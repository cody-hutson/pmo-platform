<!-- reference-durability: allow-link -->
# Failure Mode Standard

## Purpose

Every PMO skill must document its own failure surface — the specific ways that skill, in its specific domain, produces low-quality output. This document defines the format for that documentation: a conditional "do NOT do X when Y, because Z" anti-pattern framed with a 5-field template and tagged with a 5-category taxonomy.

The discipline lifts skill authoring from "generic guardrails listed" to "principal-grade domain-specific failure modes enumerated." It is distinct from — and coexists with — platform-wide guardrails inherited from CLAUDE.md § Universal Preferences and OPERATIONS.md.

## Scope

Applies to every skill in `{operations,release,core}/skills/`. Every SKILL.md must contain a `## Domain-Specific Failure Modes` section with ≥ 3 entries using the template below.

SKILL.md files without this section fail pmo-qa-auditor gate G7 (structural check). SKILL.md files with the section but with generic, non-actionable, or degenerate entries fail G7 Phase 2 (content check).

Out of scope for this document: platform-wide guardrails (governed by CLAUDE.md), runtime failure-mode *detection* infrastructure inside pmo-qa-auditor (governed by pmo-qa-auditor — see `## Relationship to pmo-qa-auditor`).

## Template

### The 5-Field Structure

Each anti-pattern documented in a skill's `## Domain-Specific Failure Modes` section uses this exact structure:

```markdown
### [Name] — [TRIG|INPUT|PROC|OUT|HAND]

- **Signature (observable signal):** What you would see in the skill's
  behavior or output that indicates this failure is happening. One or two
  sentences describing the proximate symptom a reviewer would observe.
- **Conditional:** do NOT do X when Y, because Z. (The `when Y` clause is optional — unconditional anti-patterns use "do NOT do X, because Z" and pass G7-05.)
  (The conditional MUST be one sentence in this exact form. X = the action
  to avoid. Y = the triggering context. Z = the reason, grounded in a
  consequence or principle.)
- **Root cause:** Why this failure pattern emerges — the underlying
  pressure, assumption, or misread that produces it. One or two sentences.
- **Mitigation:** What to do instead when Y is true. Specific enough that
  a junior agent could apply it; not "use better judgment."
- **Principal response vs. junior response:** How a principal-level agent
  handles this situation vs. how a junior agent typically handles it. The
  gradient surfaces the upskilling path, not just the rule.
```

Header names are fixed. G7 gate validation keys on the exact strings `## Guardrails (Platform)` and `## Domain-Specific Failure Modes` via regex. Skills currently using `## Guardrails` rename during the Wave 4 batch rollout.

### The Conditional Grammar

The Conditional field is the load-bearing sentence. Every anti-pattern reduces to this form:

> **do NOT do X when Y, because Z.**

| Component | Meaning | Failure if weak |
|---|---|---|
| **X** | The specific action to avoid — a behavior, output shape, or decision | If X is abstract ("be sloppy"), the anti-pattern cannot be applied; junior agents read it as unactionable |
| **Y** | The triggering context — an observable condition in input, state, or output | If Y is always true ("when working"), the anti-pattern collapses to a guardrail; if Y is never observable, the anti-pattern cannot be recognized |
| **Z** | The reason — a consequence, principle, or downstream effect grounded in evidence | If Z is circular ("because it's wrong") or missing, the anti-pattern provides no basis for judgment on edge cases |

**Regex for G7-05 structural validation (case-sensitive, multi-line capable):**

```
do NOT .+?(?:\s+when\s+.+?)?,\s+because\s+.+
```

The sentence must match this regex within the Conditional field. The structure is "do NOT do X[, when Y], because Z" — the `when Y` clause is **optional** (anti-patterns may be unconditional, e.g., "do NOT accept self-reported RAG status without running the derivation rule, because watermelon status..."). Multi-sentence Conditionals, reordered clauses, and paraphrases (e.g., "avoid X if Y") fail G7-05. Whitespace between keywords (`\s+`) accommodates line wrapping for readability — multi-line Conditionals are valid as long as they form one logical sentence.

## Taxonomy

### 5-Category Tagging

Every anti-pattern carries exactly one category tag in its `###` heading. The five categories span the full failure surface of a PMO skill:

| Tag | Category | Covers | Example anti-pattern |
|---|---|---|---|
| **TRIG** | Trigger / Scope | When to invoke — applying the skill in the wrong domain, methodology, or context | "do NOT apply story-point estimation when delivery_approach = Kanban, because throughput metrics tell the real story" |
| **INPUT** | Input / Evidence handling | How to treat input artifacts — trust, verification, sourcing | "do NOT accept self-reported RAG status without running the derivation rule, because watermelon status (green reported, red derived) is the most common PMO data-integrity failure" |
| **PROC** | Process / Workflow adherence | Which protocol steps to execute — sequence, gates, checkpoints | "do NOT proceed to approval when the reversibility tier is IRREVERSIBLE without a multi-stakeholder gate, because IRREVERSIBLE decisions demand heavyweight process per reversibility-protocol.md" |
| **OUT** | Output / Framing quality | Output shape — grounding, specificity, framing | "do NOT produce a stakeholder comm with `[INSERT]` placeholders, because placeholders indicate incomplete synthesis and are rejected per CLAUDE.md Guardrails" |
| **HAND** | Handoff / Escalation | Boundary and transition behavior — when to stop, surface, escalate | "do NOT swallow a cross-issue conflict in a sub-task when the conflict requires operator judgment, because hub-spoke Procedure 4 requires surfacing to the hub with Decision Briefing framing" |

The heading format is fixed:

```
### [Name] — TRIG
### [Name] — INPUT
### [Name] — PROC
### [Name] — OUT
### [Name] — HAND
```

G7-03 structural validation matches `^### .+ — (TRIG|INPUT|PROC|OUT|HAND)\s*$`. Unknown tags fail G7-03.

### How to Choose a Category

Ask, in order:

1. **Is the failure about whether to invoke the skill at all?** → **TRIG**. (Wrong methodology, wrong scope, wrong domain.)
2. **Is the failure about how input is trusted or verified?** → **INPUT**. (Unchecked evidence, trusted self-reports, missing derivation.)
3. **Is the failure about skipping or mis-ordering protocol steps?** → **PROC**. (Skipping a gate, wrong sequence, missing checkpoint.)
4. **Is the failure in the shape or grounding of output?** → **OUT**. (Vague framing, placeholders, un-evidenced claims.)
5. **Is the failure at a boundary — handoff, escalation, or stopping point?** → **HAND**. (Swallowed conflict, missed escalation, late surface.)

The ≥ 3 floor is skill-level, **not per-category**. A skill may land 3 anti-patterns all in TRIG if that is where its failure surface concentrates. Diverse coverage across categories is encouraged but not mandated.

**Cross-validation — mapping the 8 PMO-wide failure modes (pmo-qa-auditor) to this taxonomy:**

| pmo-qa-auditor failure mode | Category |
|---|---|
| Automation complacency | PROC |
| Faceless PMO | OUT |
| Echo chamber | INPUT |
| Quality drift | OUT |
| SPOF (single point of failure) | TRIG |
| Breadth burnout | PROC |
| AI hallucination | INPUT |
| Trust erosion | HAND |

All 8 cross-cutting PMO failure modes land cleanly in the 5 categories. The taxonomy is validated against known PMO anti-pattern surface, not only skill-specific ones.

## Minimum Count

### ≥ 3 Domain-Specific Failure Modes per Skill

Every SKILL.md must enumerate at least three domain-specific anti-patterns using the 5-field template above.

**Why three:** Three is the minimum that captures the input / process / output failure surface every skill has. Fewer leaves at least one axis undocumented. Scanning the current 22-skill platform:

| Distribution bucket | Skills | Floor (G7-02) | Target range (audit-revised) | v11.01c observed |
|---|---|---|---|---|
| High-complexity operational (ppm-agent, comms-writer, delivery-engine, change-management, pmo-process-designer, pmo-technical-analyst) | 6 | 3 | **6–10** | 3–4 (all six at floor or one above; **0 reached 5**) |
| Medium-complexity (artifact-generator, eval-writer, prompt-builder, pmo-skill-editor, pmo-qa-auditor) | 5 | 3 | **4–6** `[INFERRED]` | 3–4 |
| Low-complexity utility (tracker-manager, file-router, daily-status, project-initiator, weekly-status-rollup, release-executor, release-planner) | 7 | 3 | **3–4** | 3–4 |
| Authoring/infra (build-reviewer, skill-creator, implementation-planner, implementer) | 4 | 3 | **3–4** | 3–4 |

*Floor column = the universal ≥ 3 G7-02 gate (unchanged for every bucket). Target-range column = audit-data-driven expectation per bucket; it is authoring guidance, not a gate. The high-complexity 6–10 band is lifted directly from the v11.01c audit SUMMARY §1 recommendation; the medium 4–6 upper bound is `[INFERRED]` (the audit measured medium/utility/authoring at 3–4 with no expected-vs-observed gap, so it grounds the high-complexity band directly but does not independently measure the medium band). `v11.01c observed` records what the 2026-05-02 audit measured — the gap between observed and target on the high-complexity row is precisely the floor-anchoring pattern this amendment exists to correct.*

**Floor vs. target.** The ≥ 3 count is a **floor**, not a target. It is the
minimum that makes a skill minimum-viable; it is **not** the number a
well-specified complex skill should land at. The G7-02 gate enforces the floor
( < 3 fails); the target-range guidance below tells authors where a skill's
failure-mode count *should* land once its operational surface is fully
enumerated. A skill that satisfies the floor and stops is **not** thereby
well-specified — see the audit evidence below.

**Target range (audit-data-driven).** Per the v11.01c failure-mode coverage
audit (audit dated 2026-05-02; audit folder:
`failure-mode-coverage-audit-2026-05-02`, operator-instance analysis path),
the **typical complex skill should document 6–10 (target band `6-10`)
domain-specific failure modes** when its operational surface justifies the
breadth. The audit quantified that **all 22 deployed skills landed at a count
of 3 or 4, and zero exceeded 4** — including the six high-complexity
operational skills the prior forecast expected to "land 5+ naturally." Four of
those six landed at exactly 4; two landed at exactly 3. The observed reality
contradicted the prediction at **100 % of high-complexity skills**:
floor-anchored authoring, not surface-exhaustive authoring, was the norm. A
high-complexity skill landing at the ≥ 3 floor is therefore **marginal by audit
verdict** and should be expanded toward its bucket target before it is
considered well-specified. The **6–10** value is **lifted directly from the
v11.01c audit SUMMARY §1 recommendation** ("typical complex skill: 6–10
domain-specific failure modes; ≥ 3 is floor for minimum-viable skill") — the
audit is the evidence base this amendment exists to encode, not a number this
standard invents. The target is **guidance for authors, not a new gate** — G7
adds no count check above the floor; the `6-10` range is the rigor signal
pmo-skill-editor Mode A and skill-creator surface at authoring time.

**Applying the target to your skill.** Identify your skill's bucket above, then
author toward that bucket's target range — not the universal floor. A utility
skill at 3–4 is complete; a high-complexity operational skill at 3–4 is
**under-specified** and should return to the Interview and Research phase
(skill-creator) to surface the rest of its failure surface. The floor never
moves; the target tells you whether you have stopped too early.

**Why not a complexity-scaled floor:** Variable floors require judgment calls and a skill-complexity classifier. That is scope creep. Three is a defensible universal floor because it maps to the 3-axis failure space (input / process / output) every skill has.

**Three is a floor, not a ceiling.** Skills with more failure surface naturally document more. The G7 gate does not penalize exceeding three — rigor is rewarded.

**If three feels like too many:** the skill is probably under-specified. Return to the Interview and Research phase (skill-creator) and surface more of the failure surface before writing.

## Examples

Three worked examples below, one per skill-type archetype. Each follows the 5-field template with real domain detail.

### Operational skill example — ppm-agent (strategic project orchestrator)

```markdown
### Watermelon RAG acceptance — INPUT

- **Signature (observable signal):** Project status output reports a green
  RAG for a project whose derivation-rule inputs (milestone slip rate,
  budget variance, risk count) would compute amber or red.
- **Conditional:** do NOT accept a self-reported RAG status without running
  the derivation rule, because watermelon status (green reported, red
  derived) is the most common PMO data-integrity failure and silently
  erodes leadership trust.
- **Root cause:** Status reporters are incentivized to report green;
  the agent over-trusts the authoritative-looking input and skips the
  derivation. Pressure for a tidy status roll-up compounds the bias.
- **Mitigation:** Always re-derive RAG from milestone + budget + risk
  inputs per the derivation rule. If the derived RAG differs from the
  reported RAG by one step or more, surface the conflict in the output —
  do not silently choose either value.
- **Principal response vs. junior response:** Principal surfaces the
  conflict with evidence ("reported green; derived amber because
  milestone slip rate 22% exceeds 15% threshold") and flags for operator
  judgment. Junior reports whichever status the input says, or splits
  the difference as "green with amber risk" — both forms of evasion.
```

### Utility skill example — file-router (narrow routing utility)

```markdown
### Filename-only routing under content conflict — INPUT

- **Signature (observable signal):** A file is routed to a destination
  based on filename pattern, but the file's content clearly belongs to
  a different category (e.g., `transcript-2026-04-18.md` routed to
  05-Transcripts/ but containing meeting-agenda content).
- **Conditional:** do NOT route by filename alone when file content
  contradicts the filename, because filename-based routing fails
  silently when naming conventions drift and misfiled artifacts are
  the hardest routing failure to recover from.
- **Root cause:** Filename is the fastest signal; content scan is
  slower. Under time pressure, the agent shortcuts to filename even
  when a content scan was the stated mechanism.
- **Mitigation:** Run the content-classification layer on every file,
  even when the filename pattern matches. If filename and content
  disagree, route per content and surface the filename mismatch as a
  routing note on the output.
- **Principal response vs. junior response:** Principal runs both
  layers, trusts content over filename, and logs the filename drift
  as an intake-quality signal. Junior trusts the filename and moves on,
  leaving the content-contradicting file in the wrong folder.
```

### Authoring skill example — skill-creator (meta skill that creates other skills)

```markdown
### Under-specified failure surface at packaging — OUT

- **Signature (observable signal):** A draft SKILL.md is proposed for
  packaging with a `## Domain-Specific Failure Modes` section containing
  fewer than 3 entries, or with entries that restate platform guardrails
  ("do NOT invent data") rather than domain-specific failures.
- **Conditional:** do NOT package a skill when its Domain-Specific
  Failure Modes section has fewer than 3 entries or contains only
  platform-guardrail restatements, because under-specified failure
  surfaces produce skills that pass structural checks but fail in
  practice at the domain-specific boundary.
- **Root cause:** Failure-mode enumeration is the hardest part of skill
  authoring — it requires anticipating failures before they occur. Under
  time pressure, the author satisfies the letter of the ≥ 3 floor with
  generic bullets rather than domain-specific surfaces.
- **Mitigation:** Before packaging, run the G7 Phase 1 structural regex
  locally. If Phase 1 passes but the entries feel generic, return to
  Interview and Research and ask: "what is the thing this skill would
  produce that looks right but is wrong in its specific domain?"
  Three real answers is the target; less means the domain is
  under-explored.
- **Principal response vs. junior response:** Principal treats the ≥ 3
  floor as a rigor signal and enumerates 5–8 specific failures the
  skill's domain actually has, with evidence. Junior satisfies the
  floor with 3 restatements of platform guardrails and moves to
  packaging — passing G7-01 through G7-05 structurally but failing
  G7-06 through G7-08 at content review.
```

### Reorg / structure-change examples — release-planning-class workflow

The 5 entries below are drawn from the 2026-04-24 backlog reorganization session, where each pattern surfaced as an operator correction. These demonstrate the 5-field template applied to multi-skill platform-meta work (release-planning + reorg). The patterns live in this Examples section as worked examples; the consuming skill (release-planner Mode A — Backlog Analysis) inherits them as failure-surface knowledge for future reorg work without requiring a separate per-skill catalog edit.

```markdown
### Milestone count equated with sub-slice count — PROC

- **Signature (observable signal):** Agent proposes a milestone roster
  matching the sub-slice count (e.g., 60 milestones for 61 sub-slices)
  instead of grouping sub-slices into shippable capability containers.
- **Conditional:** do NOT equate sub-slice count with milestone count
  when sizing analysis produces sub-slices, because sub-slices are
  sizing units while milestones are shippable capability containers —
  collapsing them produces a milestone roster too granular to ship.
- **Root cause:** Sizing analysis output (sub-slices) is concrete and
  tempting to lift directly; the upstream step (group sub-slices into
  milestones) requires judgment and is skipped under time pressure.
- **Mitigation:** After sizing analysis, run a separate grouping pass:
  cluster sub-slices by capability boundary (functionally cohesive
  deliverables), verify each cluster is shippable end-to-end, then
  assign cluster names as milestone names. Milestone count is always
  less than sub-slice count.
- **Principal response vs. junior response:** Principal treats sub-slice
  list as input to a grouping decision and surfaces "X sub-slices → Y
  proposed milestones with rationale per group" for operator judgment.
  Junior proposes "X sub-slices → X milestones" and asks operator to
  consolidate, pushing the grouping work back to operator.
```

```markdown
### Reorg scope overreach — PROC

- **Signature (observable signal):** Agent proposes pre-bundling
  releases (assigning sub-slices to specific release versions) during
  a milestone-reorganization session whose declared scope is structure
  only.
- **Conditional:** do NOT pre-bundle releases during a milestone
  reorganization session, because reorganization scope stops at
  milestone structure; Stage 3 Bundle is a separate downstream step
  that should not be conflated with structure work.
- **Root cause:** Reorganization output naturally suggests "and then
  we'd ship in this order" — the bundling step feels adjacent and
  the agent extends scope without operator authorization. Scope
  creep masquerades as helpfulness.
- **Mitigation:** Re-read the reorganization session's declared
  scope before drafting any cross-cutting recommendations. If the
  operator said "milestone structure only," produce milestone
  structure only. Surface bundling considerations as a follow-up
  recommendation, not as in-line work.
- **Principal response vs. junior response:** Principal stops at
  the declared scope boundary and surfaces extended-scope candidates
  as separate recommendations for operator authorization. Junior
  extends scope by completing what feels like the natural next step
  and surfaces the unauthorized work as a fait accompli.
```

```markdown
### Sizing convenience over best practice — PROC

- **Signature (observable signal):** Agent proposes a milestone with
  30+ tickets (well exceeding the 5-15 ticket best-practice default)
  without independent verification that the milestone's interdependence
  justifies the size.
- **Conditional:** do NOT propose a milestone exceeding 15 tickets
  when the dependency graph has not been computed against the
  proposed milestone's contents, because milestone size beyond 15
  tickets is a structural risk requiring evidence (≥N-1 internal
  dependency edges) of internal cohesion.
- **Root cause:** Parent-slice-as-milestone or theme-as-milestone
  groupings are fast to produce but ignore the cohesion test;
  sizing is convenience-first rather than evidence-first.
- **Mitigation:** For any milestone proposed at >15 tickets, compute
  the internal dependency graph for that milestone's contents.
  Confirm ≥N-1 internal edges (where N = ticket count). If the
  cohesion test fails, split the milestone along weakest-edge cuts.
- **Principal response vs. junior response:** Principal applies
  the N-1 internal edges criterion as a structural test before
  proposing any large milestone; if the test fails, splits
  proactively and presents the split with rationale. Junior
  proposes the large milestone, surfaces "this might be too big"
  as a flag, and asks operator whether to split.
```

```markdown
### perpetuate-existing-structure-instead-of-redesign — PROC

- **Signature (observable signal):** Agent extends or replicates the
  current structure to absorb a new requirement (e.g., adds another
  one-file-per-record artifact, another parallel tracker, another
  branch on an already-overgrown conditional) instead of consolidating
  toward a better structure (a single reference, a parameterized table).
  The change makes the existing pattern bigger, never different; no
  current-state survey or target-structure rationale precedes it.
- **Conditional:** do NOT extend the existing structure to absorb a new
  requirement when the existing structure is itself the problem the work
  exists to fix, because perpetuating a known-poor structure compounds
  the defect it should retire and forecloses the review → understand →
  design → fix path that would land the better structure.
- **Root cause:** The existing structure is the path of least resistance —
  it is concrete, already in front of the agent, and "one more of the same"
  feels like progress. The review-and-redesign step is upstream, requires
  holding the whole structure in view, and is invisible unless explicitly
  invoked; under delivery pressure the agent optimizes the local edit and
  skips the structural question entirely.
- **Mitigation:** Before extending any structure, ask whether the
  structure itself is in scope to change. Run a current-state survey
  (enumerate the instances of the pattern), state the target structure
  and why it is better, and only then implement toward the target —
  not toward "one more of the existing." The Stage 5 architecture /
  best-practice / scalability-maintainability gate at the design handoff
  — tracked under the stage-gate-criteria-completeness initiative — is
  the control that catches a perpetuate-the-structure design before it
  reaches Engineering.
- **Principal response vs. junior response:** Principal treats a new
  requirement landing on a poor structure as a design trigger — surveys
  the current state, names the better structure, and proposes the
  redesign (or the explicit decision to defer it) with rationale before
  writing code. Junior adds one more instance of the existing pattern
  because it is the smallest local edit, ships the structure bigger and
  no better, and leaves the underlying structural defect for a later
  reviewer to name.
```

```markdown
### Thin self-containment in milestone descriptions — OUT

- **Signature (observable signal):** Agent writes a one-line milestone
  description ("Implement X") on first pass, requiring operator
  correction to add scope, lift, prereqs, deliverables, AC, runbook,
  and rollback.
- **Conditional:** do NOT ship a milestone description without goal
  + scope + lift + prereqs + deliverables + AC + runbook + rollback
  per the Stage 3 Bundle output spec, because milestone descriptions
  are the human-reader entry point and thin descriptions force
  operators to reconstruct context from comments and dependencies.
- **Root cause:** Title-bar conciseness bias — the agent writes a
  title-class one-liner instead of an artifact-class description,
  forgetting that the milestone description carries the full Stage 3
  output (dep graph + capacity + rationale).
- **Mitigation:** Use the Stage 3 Bundle output spec as a checklist
  when authoring any milestone description. Each of the 8 fields
  (goal, scope, lift, prereqs, deliverables, AC, runbook, rollback)
  must be present and substantive; thin entries fail self-containment.
- **Principal response vs. junior response:** Principal authors
  milestone descriptions as self-contained briefs (8 fields populated
  with cited evidence). Junior authors a one-line title-class entry
  and waits for operator review to identify the missing fields.
```

```markdown
### Version-collapse vs work-type signaling — OUT

- **Signature (observable signal):** Agent proposes all milestones
  for a multi-month roadmap under a single major version (e.g., 43
  milestones all v11.*) without using major-version boundaries to
  signal work-type transitions.
- **Conditional:** do NOT collapse all roadmap milestones to a
  single major version when the work spans distinct capability
  phases, because major-version boundaries (v11→v12, v12→v13)
  signal work-type transitions to readers and agents — collapsing
  erases the transition signal and forces external legend reading.
- **Root cause:** Version numbering is treated as an arbitrary
  identifier rather than a semantic signal; the agent reaches for
  "smallest version-bump distance" instead of "version-bump that
  signals transition."
- **Mitigation:** Identify the work-type transitions in the roadmap
  (e.g., "foundation → skills → roles → hardening → governance").
  Assign each phase its own major version. Within a phase, minor
  versions sequence the work.
- **Principal response vs. junior response:** Principal designs
  version numbering as a transition-signaling system: major-version
  bumps mark capability-class transitions; minor versions sequence
  within a class. Junior sequences chronologically (all v11.*
  through 43 milestones) and adds an external legend.
```

```markdown
### N-way consistency bypass — OUT

- **Signature (observable signal):** Collective Review Decision Briefing
  produced with cross-D upstream-compatibility scan (bullet 5) AND
  pair-wise consistency checks, but no N-way consistency table (bullet
  6 per the Stage 5 R4 standard)
  for conventions appearing in ≥2 artifacts in release scope. Detection:
  scan briefing for `N-way consistency table` heading — its absence
  when the release scope introduces or modifies a convention appearing
  in ≥2 artifacts is the signal.
- **Conditional:** do NOT approve scope-lock at Collective Review
  (Stage 5→6 boundary) when the release scope introduces or modifies
  a convention appearing in ≥2 artifacts without producing the N-way
  consistency table per
  [`.claude/rules/release-process.md` Collective Review Protocol bullet 6](../../release/governance/release-process.md),
  because pair-wise checks pass while N-way fails — the briefing
  template lacks a structural surface for N-way enumeration without
  the explicit table (evidence: spec ↔ check passed pair-wise
  for `reference/`-singular, but spec ↔ source state failed at the
  same release; N-way table would have surfaced the disagreement
  before scope-lock;  briefing).
- **Root cause:** Pair-wise consistency is fast to check (2 artifacts
  at a time); N-way requires enumerating all artifacts together and
  is structurally invisible without a template surface. The briefing
  template prior to R4  had cross-D scan (bullet 5) but no N-way
  enumeration; the hub spot-checked 1-2 pairs and inferred global
  consistency.
- **Mitigation:** Apply R4 N-way consistency table — for each convention
  appearing in ≥2 artifacts in release scope, enumerate the artifacts
  and verify agreement. Scope-lock BLOCKED on disagreement unless
  operator overrides with documented rationale. Owner column (per
  
  peer-spec ownership map) populated downstream. Composes
  with R1 evidence-grounding scan and R2 upstream-reference catalog
  citations.
- **Principal response vs. junior response:** Principal hub
  enumerates ALL N artifacts and checks all pairs — produces the
  N-way table with explicit `aligned` / `disagreement` / `N/A`
  verdicts per row. Junior hub spot-checks 1-2 pairs and infers
  global consistency; the N-way disagreement surfaces at Stage 7
  DT or post-merge retrospective rather than at Collective Review
  (`reference/` vs `references/` was caught at Stage 7 DT
  PR — N-way table would have caught it 2 stages earlier).
```

```markdown
### Concurrence without verification — PROC

- **Signature (observable signal):** Hub Decision Briefing states
  concurrence with spoke recommendation; no Empirical Verification
  subsection per [`hub-spoke-bridge.md` Operating Principle](../../release/references/how-to/hub-spoke-bridge.md)
  adversarial evaluation clause, OR verification artifact omitted
  (no command quoted, no observed result quoted, no file:line citation).
  Detection: scan briefing for `Empirical Verification` per-recommendation
  subsection — its absence on testable spoke claims is the signal.
- **Conditional:** do NOT concur with a spoke recommendation at any
  Decision Briefing touchpoint (Procedure 4 / Procedure 5 / Procedure 0
  / Procedure 7) when the spoke recommendation contains ≥1 testable
  claim (file exists / command produces output / state matches schema),
  because concurrent-by-default operating posture treats spoke
  recommendations as authoritative without disconfirming-evidence
  interrogation — hub-level snapshot freshness gaps slip past every
  downstream stage (per 
  R3 in-session pattern N=3 + retrospective evidence).
- **Root cause:** The hub's prior operating posture (concurrent-by-default
  per pre- Operating Principle "Two-layer evaluation" framing) made
  empirical verification optional. Concurrence-without-verification was
  the path of least friction; the structural enforcement surface to make
  it non-compliant did not exist until R3 introduced the per-recommendation
  Empirical Verification subsection.
- **Mitigation:** Apply R3 Adversarial Hub Review — for each testable
  claim in spoke output, run verification (read cited file, run cited
  command, sample cited data) BEFORE producing the Decision Briefing.
  Cite verification artifacts in the per-recommendation Empirical
  Verification subsection per the template at
  [`hub-spoke-bridge.md` Procedure 4 step 6](../../release/references/how-to/hub-spoke-bridge.md):
  Claim → Verification command → Observed result → Verdict (verified-matches /
  verified-diverges / unverifiable-escalate-to-operator). Concurrence
  without verification artifact is non-compliant. Hub may diverge from
  spoke pending operator clarification when verification cannot be run.
- **Principal response vs. junior response:** Principal hub runs
  verification before concurring — reads PR diff before Stage 9 GO;
  runs `gh pr view --json` before Stage 12 Execute; greps cited file:line
  before concurring with Stage 5 canonicalization claim. Junior hub
  concurs from spoke surface rationale alone ("looks correct",
  "platform conventions"); the snapshot-freshness gap surfaces at
  Stage 7 DT or post-merge retrospective rather than at briefing time.
```

```markdown
### Spec-vs-reality divergence at canonicalization — INPUT

- **Signature (observable signal):** Stage 5 Solutioning spoke output
  canonicalizes a convention (dir name, frontmatter field, file path
  pattern, regex, identifier format, naming scheme, numeric threshold)
  without an inspectable Evidence-Grounding artifact (current-state
  enumeration + canonical-choice justification per
  [`evidence-grounding-standard.md`](../standards/evidence-grounding-standard.md)).
  The spec asserts convention `X` while reality has variants
  `{X, Y, Z}` across the codebase; downstream stages (Stage 7 DT or
  later) catch the divergence when checks run against real artifacts.
- **Conditional:** do NOT canonicalize a convention at Stage 5
  Solutioning when the current state of that convention has not been
  surveyed across the codebase, because review-pipeline stages
  between Stage 5 and Stage 7 DT have no evidence-grounding gate —
  invented canonical values become spec-vs-reality defects that
  surface as Tier 2 [SCOPE CHANGE] during Engineering or DT (per
  R1
  retrospective evidence: `reference/` vs `references/` 4-way
  disagreement at briefing was caught at Stage 7 DT PR after
  Engineering completed against the invented canonical).
- **Root cause:** The Solutioning spoke has implementation context for
  its issue's design surface but not for current-state convention
  distribution across the codebase. Without an evidence-grounding
  requirement, the spoke canonicalizes from file-layout-section
  intuition or single-sample inspection — the upstream survey step
  is structurally invisible.
- **Mitigation:** Apply [`evidence-grounding-standard.md`](../standards/evidence-grounding-standard.md)
  to every Stage 5 spoke output that canonicalizes a convention.
  Required artifact: 2-part schema (current-state enumeration with
  reproducible grep evidence + canonical-choice justification citing
  audit / upstream / ADR). Out-of-scope drift observed during survey
  is logged with routing (Tier 1 [ADJUST] / next-release issue /
  accepted-residual). Collective Review Decision Briefing rejects
  scope-lock approval when a canonicalization is detected without
  the artifact (per
  [`.claude/rules/release-process.md`](../../release/governance/release-process.md)
  Collective Review Protocol bullet 6 — R1 ↔ R4 composition).
- **Principal response vs. junior response:** Principal surveys
  current state with a reproducible grep across the codebase BEFORE
  selecting the canonical value, cites the survey result in the
  evidence-grounding artifact, and surfaces out-of-scope drift to
  downstream stages with routing. Junior selects the canonical from
  file-layout-section intuition or single-sample inspection; the
  divergence surfaces at Stage 7 DT as a Tier 2 [SCOPE CHANGE] that
  forces release-branch iteration.
```

```markdown
### Cascade-omission at count update — PROC

- **Signature (observable signal):** Stage 5 spec enumerates a count-update line
  (e.g., "20 custom skills → 19" in the `## Tracked Skills` header) and the file
  appears in the spec's affected-files matrix, but the spec does NOT enumerate
  adjacent occurrences of the OLD value within the same file (e.g., "16 of 20
  custom skills have packages" narrative on line 30; "20 custom skills (all
  git-tracked)" on line 96). Engineering implements the enumerated cells faithfully;
  the adjacent occurrences ship unchanged. Detection: post-Engineering
  `grep -nE '<old-value-regex>' <affected-file>` returns non-zero matches in files
  the spec already touched. PR [ADJUST] evidence: DT-596-1 (skill-deployment.md
  line 30) + DT-596-2 (architecture-overview.md line 96) — 2 Tier 1 [ADJUST]
  findings from one cascade event.
- **Conditional:** do NOT author a Stage 5 change spec for a count / enumeration /
  threshold update when the spec enumerates only the primary update cell, because
  count drift cascades through adjacent narrative cells, parenthetical references,
  and metadata in the same file — the cascade-incomplete spec ships with
  documentation drift that DT catches as Tier 1 [ADJUST] findings 1-3 commits
  later (DT findings DT-596-1 + DT-596-2 from one 20→19 cascade).
- **Root cause:** Spec authoring focuses on the cell the issue body or refactor
  goal named ("update Tracked Skills header"); adjacent occurrences ("16 of 20
  custom", "20 custom skills") feel like background detail and are not surveyed.
  Engineering self-verification grep is keyed on the new value or the changed
  scope name, not on the OLD value across the affected file — so the cascade gap
  is invisible until Stage 7 DT runs its own grep sweep.
- **Mitigation:** When a Stage 5 spec touches a count, enumeration, or threshold
  in any file in its affected-files matrix, the spec MUST include a
  `### Cascade-Sweep` block enumerating EVERY occurrence of the OLD value in
  EVERY file × OLD-value pair in scope, with per-occurrence disposition
  (UPDATE / PRESERVE / N/A) + rationale. Sweep command:
  `grep -nE '<old-value-regex>' <file>` for each pair; output preserved verbatim
  in the spec. Full schema at
  [`release/references/pipeline/stage-05-solutioning.md § 5.6`](../../release/references/pipeline/stage-05-solutioning.md).
  Forcing function: `design-review-checklist.md § Section 3.5` self-check at
  Phase A4 → A5 transition rejects incomplete sweep block.
  **Automated detection (L5):** `pmo-qa-auditor` gate **G8** (Cascade-Completeness
  Verification) is the post-Engineering, QA-time detection surface — it re-runs each
  declared sweep against the changed-file set and FAILs on any un-enumerated OLD-value
  occurrence (`file:line` cited), catching this failure mode automatically before DT
  (see [`cascade-completeness-detection.md`](../skills/pmo-qa-auditor/references/cascade-completeness-detection.md)).
  **Cutover:** Applies
  to all releases going forward — to any Stage 5 spec touching a count,
  enumeration, or threshold.
- **Principal response vs. junior response:** Principal authors the
  `### Cascade-Sweep` block as a deterministic grep table — runs the grep for
  each (file × OLD value), pastes the results verbatim, assigns disposition per
  row with rationale, and the spec ships with the sweep evidence inline. Junior
  names only the primary update cell ("update line 14 header → 19"), assumes
  Engineering will sweep adjacent occurrences during implementation, and the
  cascade-incomplete spec produces Tier 1 [ADJUST] DT findings 1-3 commits later
  (the failure mode).
```

### utc-drift-spec-contradiction — PROC

- **Signature (observable signal):** Stage 5 spec hardcodes a date in spec text
  (e.g., `pmo-platform/analysis/<audit-name>-2026-05-01/`) that MUST match a
  literal date in ≥1 downstream load-bearing artifact (folder path, AC verifier
  identifier, ADR source-observation reference). Stage 6 execution crosses a
  UTC day boundary relative to the operator-local date used at authoring;
  `date -u +%Y-%m-%d` at first commit returns a different date than the spec
  literals. Engineering faces an unresolvable choice: honor the literal
  `date -u` instruction (force edits across multiple files + break AC
  verification) OR honor the spec's hardcoded references (Tier 1 [ADJUST]
  documentation burden).
- **Conditional:** do NOT hardcode dates in Stage 5 specs when the date is
  consumed by load-bearing downstream identifiers AND the Stage 5 author is
  not the Stage 6 executor in the same UTC day, because the contradiction
  forces Tier 1 [ADJUST] or AC-verification breakage at Stage 6.
- **Root cause:** Date literals in Stage 5 spec assert a moment-in-time
  binding that spec cannot honor — the spec author cannot know when
  Stage 6 will execute relative to UTC. The binding is asserted; reality
  diverges; Engineering pays the cost.
- **Mitigation:** Apply
  [`core/standards/date-variable-convention.md`](../standards/date-variable-convention.md) —
  define `${AUDIT_DATE_UTC}` at top of spec; reference variable (not literal)
  in all load-bearing positions; resolve at Stage 6 first commit via
  `date -u +%Y-%m-%d`. Engineering propagates the resolved value consistently
  across all artifacts in the release. **Cutover:** Applies to all releases
  going forward — to any Stage 5 spec with load-bearing dates.
- **Principal response vs. junior response:** Principal recognizes the
  binding-assertion problem at spec authoring time and reaches for a variable
  (`${AUDIT_DATE_UTC}`) — the spec defers date resolution to Stage 6 first
  commit and propagates mechanically. Junior writes the literal date because
  "today is 2026-05-01" and trusts the date will hold through Stage 6
  execution; spec ships with embedded contradictions waiting to fire at the
  next UTC day boundary.
- **Originating evidence:** Stage 6 Engineering Pass 1
  + `pmo-platform/analysis/file-overlap-audit-2026-05-01/SUMMARY.md` § 1
  UTC drift note. Tier 1 [ADJUST] documented at Stage 6.

### Hub-spoke chip-prompt examples — release-execution-class workflow

The entries below address the `snapshot-as-current-state` root failure mode at hub-and-spoke chip-construction / recommendation-rendering surfaces. The pattern emerged N=4 in-session (2026-04-25 through 2026-05-15), with a fifth instance (2026-05-16 Stage 6 sub-task body templates) confirming durability. Sister failure modes share the root pattern but address distinct surfaces — recommendation rendering (this entry, `Audit snapshot as current state`) vs. chip-prompt construction (`Chip-prompt summary embedded as canonical content`, codified at a sibling sub-task). Both cite [`decision-discipline.md` § 2.1.1 Sub-mechanism — Audit-Snapshot Reconciliation](../disciplines/decision-discipline.md) as canonical mitigation home.

```markdown
### Audit snapshot as current state — INPUT

- **Signature (observable signal):** Hub renders a recommendation,
  Decision Briefing, or routing decision whose load-bearing platform
  context is an audit `recommendations.md` row, gap-analysis bullet,
  closed-sub-task body, or prior-stage triage output more than ~24
  hours old — without executing verification primitives against
  current state (no `gh issue list --search`, no `git log --follow
  <cited-file>`, no `grep` for cited-symbol existence). The
  recommendation lifts artifact contents verbatim, treating
  enumerated items as if all still pending.
- **Conditional:** do NOT lift an audit-derived recommendation
  into hub output when the source artifact is older than the most
  recent merge to `main` for the affected files, because analysis
  artifacts are forward-looking by convention but accumulate
  shipped status invisibly — recommending already-shipped work
  wastes operator time and erodes consumer trust.
- **Root cause:** Sister failure mode `hub-summary-as-canonical`
  (see `hub-spoke-bridge.md`
  Procedure 3 §spec-anchor — chip-prompt-construction surface variant)
  shares the `snapshot-as-current-state` root pattern. Both surfaces
  treat a point-in-time artifact as if it were live state; the
  recommendation-surface variant manifests at briefing rendering, the
  chip-prompt-construction variant manifests at sub-task scaffolding.
  Empirical basis: N=4 in-session drift instances (2026-04-25 pre-shard
  path; 2026-05-01 closed-PR re-recommendation; 2026-05-09 closed-Issue
  dep-met assumption; 2026-05-15 stale-summary canonical) + drift 5
  (2026-05-16 Stage 6 sub-task body templates, F-1 [ADJUST] commit
  2c6293f). The class is durable, not anecdotal.
- **Mitigation:** Apply the audit-snapshot reconciliation
  sub-mechanism at `decision-discipline.md` § 2.1.1 BEFORE
  surfacing the recommendation: execute primitive 1 (`gh issue list
  --search "<symbol> in:title,body" --state all`) for existing
  tracking; primitive 2 (`git log --follow <cited-file> --since=
  "<artifact-date>"`) for post-artifact commits; primitive 3 (`grep
  -nE "<cited-symbol>" <cited-file>`) when recommendation proposes
  a specific symbol. Append `[VERIFIED <YYYY-MM-DD>: <command> →
  <result>]` evidence trailers per primitive executed. Consumer
  binding to fire this sub-mechanism at the hub-recommendation
  surface: [`hub-spoke-bridge.md` Procedure 0a — Audit-Aware
  Orientation](../../release/references/how-to/hub-spoke-bridge.md).
- **Principal response vs. junior response:** Principal treats
  audit artifacts as point-in-time evidence, executes verification
  primitives before surfacing any artifact-derived recommendation,
  and lets the trailers' negative results gate proceed-vs-surface
  to operator. Surfaces "potentially-shipped" rather than
  recommending if any primitive returns matches. Junior reads the
  artifact, lifts enumerated items verbatim, and renders them as
  current-state recommendations — pushing verification work back
  to operator who must re-read the artifact they already actioned.
```

```markdown
### Chip-prompt summary embedded as canonical content — INPUT

- **Signature (observable signal):** A spoke session produces work
  consistent with a chip-prompt summary that diverges from the
  canonical source spec the summary purported to compress.
  Detection: spoke output cites the chip-prompt summary (e.g.,
  "per the chip prompt: cells map to X") rather than the canonical
  source (e.g., "per upstream main comment §4 cells map to Y"). The
  divergence may be subtle (paraphrased scope), structural (omitted
  fields), or fabricated (inferred files that do not exist on the
  current filesystem).
- **Conditional:** do NOT embed a summarized version of a canonical
  source spec in a chip prompt when the spoke needs the spec for
  scope-defining content (acceptance criteria, schemas, protocols,
  gate criteria), because the chip prompt is a snapshot of hub
  understanding at chip-launch time and diverges from the canonical
  source as governance evolves — the spoke inherits the snapshot
  as authoritative and produces work consistent with the snapshot,
  not the source.
- **Root cause:** Sister failure mode `Audit snapshot as current
  state — INPUT` (above; recommendation-rendering surface variant,
  codified by `hub-spoke-bridge.md`
  Procedure 0a — Audit-Aware Orientation) shares the
  `snapshot-as-current-state` root pattern. Both surfaces treat a
  point-in-time artifact as if it were live state; the
  recommendation-surface variant manifests at briefing rendering,
  the chip-prompt-construction variant (this entry) manifests at
  spoke-launch synthesis. Chip prompts compound the pattern because
  the snapshot persists in the prompt long after construction —
  every read by the spoke re-trusts the snapshot. Originating
  evidence: audit DT-1 Pass 1 finding
  — E1 chip prompt summarized upstream
  main comment §4 cell-coverage scope inline rather than directing
  spoke to read the canonical source; HUB-DISCIPLINE CORRECTION
  applied to E2 / E3 / E4 chip prompts (operationally in use,
  uncodified until this entry).
- **Mitigation:** Construct chip prompts so that scope-defining
  content references canonical sources by file path / issue number
  / section anchor, with explicit `"Read CANONICAL SOURCE SPECS
  directly"` direction to the spoke. Hub MAY include orientation
  summaries (release context, sub-task background) but MUST NOT
  substitute its summary for the source on scope-defining content.
  Consumer binding to fire this discipline at the chip-prompt
  construction surface: [`hub-spoke-bridge.md` Procedure 3 §Chip
  Prompt Spec-Anchor Discipline](../../release/references/how-to/hub-spoke-bridge.md). Sister
  mitigation surface (recommendation-rendering): [`hub-spoke-bridge.md`
  Procedure 0a — Audit-Aware Orientation](../../release/references/how-to/hub-spoke-bridge.md).
  Canonical mitigation home for both surfaces: [`decision-discipline.md`
  § 2.1.1 Sub-mechanism — Audit-Snapshot Reconciliation](../disciplines/decision-discipline.md).
- **Principal response vs. junior response:** Principal authors
  chip prompts that name the canonical source and direct the spoke
  to read it (e.g., `"Read release/references/pipeline/stage-05-
  solutioning.md § 5 directly for Phase A1-A5 procedure"`); the
  spoke executes against current source content. Junior compresses
  the source into a chip-prompt section and trusts the compression
  ("the chip prompt says A1-A5 do X, Y, Z"); the spoke executes
  against a snapshot that has drifted from current source content
  — and the hub inherits the drift downstream when the spoke's
  output cites the snapshot as authority.
```

```markdown
### Chip-prompt embedded arithmetic without verification — INPUT

- **Signature (observable signal):** A chip prompt enumerates a
  pre-computed count or sum of items derived from multiple sources
  (acceptance criteria across an issue body + sibling-issue body +
  milestone deliverable description; sub-task count across a release;
  verification-table row count) where the stated total does not equal
  the sum of its own cited addends. Detection: the prompt states a
  derivation inline (e.g., "N rows: a + b + c") and `a + b + c ≠ N`;
  the spoke then carries reconciliation overhead, or proceeds on the
  wrong number when the verification step is skipped.
- **Conditional:** do NOT embed a pre-computed count or sum in a chip
  prompt when the hub has not run the derivation against the actual
  sources at chip-authoring time, because the arithmetic is wrong at
  authoring time (a hub computation error, not snapshot drift) and the
  spoke either absorbs the reconciliation cost or inherits the wrong
  total.
- **Root cause:** Sister failure mode `Chip-prompt summary embedded as
  canonical content — INPUT` (above) shares the same hub-orchestration
  root class but a DISTINCT failure mechanism: that entry is about a
  *summary* of source content drifting from the source over time
  (snapshot-as-current-state); THIS entry is about a *computation* of
  source enumerations being incorrect at the moment of authoring. The
  pressure is the hub's impulse to pre-resolve a count for spoke
  convenience or gate-checking without executing the derivation —
  mental arithmetic substituted for a verified count.
- **Mitigation:** Fire the chip-prompt arithmetic discipline at
  [`hub-spoke-bridge.md` Procedure 3 §Chip Prompt Arithmetic
  Discipline](../../release/references/how-to/hub-spoke-bridge.md)
  BEFORE issuing the prompt. Prefer the derivation-logic pattern —
  reference the derivation (one row per AC; source ACs from issue body
  A, issue body B, and the milestone deliverables; spoke verifies the
  row count against the actual AC count) rather than a pre-computed
  sum, so there is no embedded total to drift. If a count must be
  embedded (spoke-side gate-checking, estimation), run the derivation
  against the actual sources first and state the verified sum with the
  derivation cited; if the hub cannot verify at authoring time, mark
  the count explicitly approximate and direct the spoke to verify.
- **Principal response vs. junior response:** Principal authors chip
  prompts that reference derivation logic rather than a pre-computed
  total, and — when a count is unavoidable — verifies it against the
  sources before issuance and cites the reproduction command. Junior
  performs the addition in-prompt, embeds the total without checking
  it (e.g., "build a 14-row table: 11 + 3 + 4"), and pushes the
  reconciliation onto the spoke — which either burns attention
  reconciling the discrepancy or silently proceeds on the wrong
  number. Originating evidence (release-lineage, depersonalized): at
  the v11.01b Collective Review precedent a hub-authored Stage 6
  Engineering chip prompt asserted a verification table of "14 rows:
  11 ACs from issue body A + 3 ACs from issue body B + 4 deliverable
  ACs from the milestone description" — the cited addends sum to 18,
  not 14; the sub-task instruction body independently stated a third
  divergent figure. The spoke handled it gracefully (chose the
  comprehensive 18-row coverage and flagged for the operator at Stage
  9), but the reconciliation consumed Engineering attention.
```

```markdown
### Decision-Briefing under-loading — OUT

- **Signature (observable signal):** A hub Decision Briefing fires an `AskUserQuestion` (or equivalent in-chat) call whose immediately-preceding chat turn is missing the full rendered briefing, OR the briefing's option set omits an option the operator's prior stance implies, OR a decision is framed against a spec the hub cites but did not read this session. The reviewer sees a structured prompt the operator must answer from a curated or thin summary rather than from a rendered, fully-enumerated, source-grounded briefing.
- **Conditional:** do NOT fire the AskUserQuestion call when the full Decision Briefing has not been rendered in chat, the option space has not been enumerated to include stance-implied options, or a cited spec has not been read this session, because an under-loaded briefing forces the operator to decide on incomplete information and silently narrows the decision to the hub's curated subset.
- **Root cause:** rendering the full briefing and reading every cited source reads like slower work than surfacing the recommendation directly; under throughput pressure the hub defaults to a remembered summary and a recommendation-shaped option set, and the missing options and unread sources are invisible in the prompt itself.
- **Mitigation:** satisfy the five Information Sufficiency gates in `hub-spoke-bridge.md` § Operating Principle: Decision Briefing before any gate call — pre-load every cited source, enumerate the full option space including stance-implied options (stance-scan pre-check), render the full briefing in chat, then call `AskUserQuestion` with the `preview` field as a complement; treat a gate call lacking the preceding rendered briefing as `[STRUCTURAL-DEFECT: unrendered-gate]`.
- **Principal response vs. junior response:** a principal reads every cited spec, enumerates the options the operator would plausibly choose (not only the recommended one), renders the whole briefing in chat, and only then asks — treating the prompt as a selection over information the operator already has; a junior surfaces the recommendation with a thin option set, asks first, and back-fills context only if the operator pushes back.
```

## Relationship to Platform Guardrails

Every SKILL.md now has two distinct sections:

- **`## Guardrails (Platform)`** — platform-wide generic guardrails inherited from CLAUDE.md § Universal Preferences and OPERATIONS.md. Per-skill files may link to canonical definitions rather than duplicate. Applies to all skills uniformly.
- **`## Domain-Specific Failure Modes`** — skill-specific conditional anti-patterns per the template in this document. ≥ 3 entries. Unique to each skill's domain.

The two coexist. Neither replaces the other. Platform Guardrails answer *"what rules apply to every skill?"* Domain-Specific Failure Modes answer *"what rules apply to this specific skill because of what it specifically does?"*

Evidence that the distinction matters: platform guardrails fire generically (status theater, invention, task dumping). They do not tell ppm-agent's reviewer *how watermelon RAG hides in PPM output*, or file-router's reviewer *how filename drift misroutes content*. Those are the domain-specific surfaces this document governs.

## Relationship to G7 Gate

pmo-qa-auditor Mode A includes gate **G7 — Domain-Specific Failure Mode Discipline**, which fires when the output under audit is a SKILL.md file. G7 is a two-phase check.

### Phase 1 — Structural (Tier 1, auto, deterministic)

| ID | Check | Method | Pass criterion |
|---|---|---|---|
| G7-01 | SKILL.md contains a `## Domain-Specific Failure Modes` heading | regex: `^## Domain-Specific Failure Modes\s*$` (multiline) | Exactly one match |
| G7-02 | Section contains ≥ 3 `###` subsections (one per anti-pattern) | Count `^### ` lines between `## Domain-Specific Failure Modes` and next `## ` heading | ≥ 3 |
| G7-03 | Each subsection header carries one of 5 category tags | regex: `^### .+ — (TRIG\|INPUT\|PROC\|OUT\|HAND)\s*$` per subsection | All subsections match; no unknown tags |
| G7-04 | Each subsection contains all 5 required fields | For each subsection, search for bold labels: `\*\*Signature`, `\*\*Conditional:\*\*`, `\*\*Root cause:\*\*`, `\*\*Mitigation:\*\*`, `\*\*Principal response vs\. junior response:\*\*` | All 5 present per subsection |
| G7-05 | Conditional field matches the "do NOT X[, when Y], because Z" form | regex (case-sensitive, multi-line capable): `do NOT .+?(?:\s+when\s+.+?)?,\s+because\s+.+` within the Conditional field. The `when Y` clause is optional. | Every subsection matches |

### Phase 2 — Content (Tier 2, LLM-graded, recommend)

| ID | Check | Method | Pass criterion |
|---|---|---|---|
| G7-06 | Each anti-pattern is domain-specific, not a generic platform guardrail restated | LLM grader reads each anti-pattern + CLAUDE.md Guardrails list; scores "domain-specificity" 1–5 | Mean ≥ 4.0 across subsections; individual scores ≥ 3 |
| G7-07 | Mitigation is actionable (not "use better judgment") | LLM grader scores each Mitigation field for actionability 1–5 | Mean ≥ 4.0 across subsections |
| G7-08 | Principal-vs-junior gradient is meaningful (not a restatement) | LLM grader scores whether the two responses are qualitatively different, 1–5 | Mean ≥ 3.5 across subsections |

### G7 Verdict

- All Phase 1 structural checks PASS **and** all Phase 2 content checks meet their thresholds → **PASS**
- All Phase 1 PASS, one or more Phase 2 below threshold → **CONDITIONAL PASS** (with findings)
- Any Phase 1 check FAIL → **FAIL** (with specific regex non-match cited as evidence)

## Relationship to pmo-qa-auditor

The pmo-qa-auditor (QA Auditor — Add 8 failure mode detection) is **complementary** to this standard, not redundant. Clear separation of concerns:

| Dimension | This standard (failure-mode-standard) | pmo-qa-auditor |
|---|---|---|
| **What it establishes** | Authoring discipline: how skills document their own failure modes | Detection infrastructure: how pmo-qa-auditor detects 8 specific PMO-wide anti-patterns at runtime |
| **Scope** | All 22 skills (every SKILL.md) | pmo-qa-auditor only (1 skill) |
| **Subject of audit** | SKILL.md authoring rigor (static analysis of skill definitions) | Live skill outputs (runtime analysis of produced artifacts) |
| **Format** | 5-field conditional template + 5-category taxonomy (generic schema) | 8 named detectors with specific indicators and thresholds (specific detection set) |
| **Milestone** | skills-platform-foundations | skills-qa-auditor |
| **Gate** | G7 (new, in pmo-qa-auditor) | Not a gate — detectors are Mode-level capabilities |

**Handoff specification for pmo-qa-auditor:** When Stage 4 Planning runs for pmo-qa-auditor, the release plan must direct:

> *"Express the 8 failure-mode detectors using the 5-field conditional template and 5-category taxonomy per `core/standards/failure-mode-standard.md`."*

Each of pmo-qa-auditor's 8 detectors is written using this document's 5-field template when documented in `pmo-qa-auditor/SKILL.md`. Worked conversion for "Automation complacency" (category: PROC):

- **Signature:** Agent output cites automated results without evidence of cross-check.
- **Conditional:** do NOT accept an automated gate result when the underlying check has not been sampled for correctness in the last N runs, because automation complacency erodes detection over time.
- **Root cause:** Automation success rate creates false confidence; sampling discipline decays silently.
- **Mitigation:** Sample at rate 1/N runs; flag drift if sampled-vs-automated divergence exceeds threshold.
- **Principal response vs. junior response:** Principal re-derives the check outcome from source data on sampled runs; junior trusts the automated verdict and moves on.

**No duplication risk:** pmo-qa-auditor adds runtime detectors for live outputs; this standard defines the authoring format those detectors live in. Separate gate infrastructure. pmo-qa-auditor's own `## Domain-Specific Failure Modes` section easily exceeds the ≥ 3 floor by inheriting from its detectors — it does not need a separate G7 of its own.

## Decision Notes

Inline rationale for non-obvious design decisions, per the platform pattern. No standalone ADR.

**5-field template vs. 3-field minimal.** A 3-field (name / conditional / mitigation) option was rejected because it collapses to the existing Guardrails format — no principal-vs-junior gradient, no observable signature, no root cause. The 5-field template is a direct lift from the KB `PMO-Reference-Model.md` anti-pattern catalog; it matches canonical PMO practice and is structurally auditable at both the regex layer (Phase 1) and the content layer (Phase 2).

**5-category taxonomy vs. 4 or 6.** Four categories (collapsing INPUT and OUT into "data handling") loses the directionality distinction — reviewers hunt input-trust failures differently than output-framing failures. Six categories (splitting PROC into "sequence" and "gate") is superficial — both are workflow-adherence failures. Five covers the failure surface every PMO skill has with no overlap and no gaps, and it validates cleanly against pmo-qa-auditor's 8 cross-cutting failure modes.

**≥ 3 floor vs. complexity-scaled floor.** A variable floor scaled by skill complexity was considered and rejected. Variable floors require a skill-complexity classifier and judgment calls at every skill — scope creep. Three is defensible as a universal floor because it maps to the 3-axis input / process / output failure space every skill has. Skills with richer failure surfaces exceed three naturally; the gate does not cap the ceiling.

**Fixed header names.** `## Guardrails (Platform)` and `## Domain-Specific Failure Modes` are fixed strings, not flexible. G7-01 keys on the exact string for structural validation. Flexibility here buys no authorial freedom and costs deterministic gate behavior.

**Case-sensitive "do NOT" regex.** Lowercase `do not` or uppercase `DO NOT` do not match G7-05. The fixed form is a rigor signal — authors who paraphrase break the pattern and fail the gate, which is the intended behavior. The template is a contract, not a suggestion.

---

*Standard for `## Domain-Specific Failure Modes` authoring. Consumed by pmo-qa-auditor gate G7 (Wave 2) and skill-creator Interview/Write enforcement (Wave 2). 22-skill SKILL.md rollout in Wave 4. pmo-qa-auditor inherits this format for its 8 failure-mode detectors.*

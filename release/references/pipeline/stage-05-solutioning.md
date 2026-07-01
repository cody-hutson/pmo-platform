<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->
# Stage 5: Solutioning

> **Source:** Stage 5 originating spec
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
This is the **design** stage of the pipeline — where the solution is designed, after the early stages have mapped state and surfaced gaps and before Engineering builds. Resolve technical design decisions, validate feasibility, and produce implementation-ready specifications so Engineering receives unambiguous instructions — not open questions.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Design technical approach; validate feasibility; prototype | Same — compressed. "Prototype" = spike when design uncertain |
| Governance Focus | Design review gates; architecture governance | Operator reviews ADRs before Engineering proceeds |
| Artifact Inputs | Requirements, architecture standards | Release plan, platform architecture, current file state |
| Artifact Outputs | Design docs, ADRs, prototype results | ADRs (GitHub Issues), design specs, blast radius analysis |

Key compression: No multi-team architecture review boards or formal HLD/LLD. Agent-assisted design analysis + operator approval of key decisions.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Decision maker: Human operator | — | — | Tier 3 |
| Design analysis (primary): Principal Eng Skill #9 | Architecture Decision & NFR Governance | Mode 1 (Architect) | Tier 1/2 split |
| Design review (primary): Principal Eng Skill #9 | Build-vs-Buy & Design Review | Mode 2 (Architect) | Tier 2 (Recommend) |
| Implementability (secondary): Principal Eng Skill #9 | Implementation & Code Quality | Mode 3 (Tech Lead) | Tier 1 (Auto-flag) |
| Debt assessment (secondary): Principal Eng Skill #9 | Tech Debt & Mentoring | Mode 4 (Tech Lead) | Tier 1 (Auto-flag) |

## 4. Inputs
From Planning: release plan, implementation sequence, change specs, risk register.
Set at Solutioning: ADR issues, refined change specs, blast radius analysis, implementability assessment, skip rationale.
Contextual: platform architecture (CLAUDE.md, core/rules/), current file content, existing patterns.

## 5. Process
**Phase 0 — Activation Gate (all-or-nothing per release):**
Activate when ANY issue matches: new file with non-trivial content, skill logic changes, structural design decisions, multiple valid approaches, cross-cutting 3+ governance files, blast radius uncertainty. Skip otherwise. Canonical trigger definitions + per-release evaluation pattern at [`planning-solutioning-handoff.md`](../../../core/standards/planning-solutioning-handoff.md).

For the intake-side guidance that correctly defers design here (the 5-test rule, especially T2 Determinate design), see [`intake-style-guide.md`](../how-to/intake-style-guide.md) §2 and the Stage 5 vs. Intake decision table in §5. Tickets that mark design `[ASSUMPTION – CONFIRM]` at intake explicitly route to this gate.

**Phase 0.5 — Re-Review Delta per [triage-design-rereview.md](../standards/triage-design-rereview.md) § 6:** when Stage 4 re-review predates Stage 5 entry by >7 days OR Stage 5 A3 blast radius exposes new context, run delta against D2 + D3 (or full re-review per § 6 conditions). C3 classifications trigger Tier 0 — Premise Rejection per [release-process.md](../../governance/release-process.md) Inter-Stage Feedback Protocol. Always-fires for releases subject to cutover. Phase 0.5 is a canonical discovery-class activity per [discovery-discipline.md](../../../core/disciplines/discovery-discipline.md) § 7.2 — outputs the 5 named discovery outputs (open-question register / gaps with F9 case-classification / scope-cleavage points / premises requiring re-review / evidence-quality labels) per discovery-discipline § 4.

**Phase 0.7 — Mid-Spoke Cross-Ticket Scope Detection (conditional):** During design, a Stage 5 spoke watches for evidence that its scope overlaps a sibling ticket in the same milestone — so a real cross-ticket coupling is surfaced to the hub at design time rather than discovered after two spokes have built conflicting work. The detection runs on two heuristics:

1. **File-overlap against the Stage-4 Contention Map** (NOT a live diff — Stage 5 spokes write no files, so there is nothing to diff). The spoke compares the concrete paths in its own File Change Matrix against the [Stage-4 Contention Map](stage-04-planning.md) for the release: does a sibling ticket's row name ≥1 of the same concrete path?
2. **Semantic-similarity against sibling issues in the same milestone.** Does a sibling ticket's stated scope (its title + acceptance criteria) describe the same capability surface this spoke is designing — even when the file sets differ?

**Escalation threshold (false-positive bound).** Escalate ONLY when a **strong** signal holds: a file-overlap on a non-append-pattern file (a file where two writers genuinely collide, as opposed to an append-only surface like a log or an alphabetical list where concurrent additions merge cleanly), AND/OR a sibling sharing ≥1 concrete path. A single **weak** signal alone — a semantic resemblance with no shared concrete file, or an overlap confined to an append-pattern file — is **logged in the spoke output, not escalated**. This two-signal-or-strong-single bar bounds false positives on shared high-traffic files (a file every spoke touches is not, by itself, evidence of a cross-ticket scope collision).

**On a positive detection,** the spoke posts a Tier 2 `[SCOPE CHANGE]` finding to the hub per [release-process.md](../../governance/release-process.md) Inter-Stage Feedback Protocol BEFORE the release-level Collective Review — naming the sibling ticket, the overlapping path(s) or capability, and which heuristic fired. The detection **does NOT self-authorize** a merge, split, or scope change: it is a finding routed up; the hub renders the disposition (expand-scope-now vs hold-for-Collective-Review) at its [Stage 5 Mid-Solutioning Cross-Ticket Escalation Handler](../how-to/hub-spoke-bridge.md) and surfaces the call to the operator.

*Cutover (reflexive): this rule applies to releases entering Stage 5 strictly AFTER the introducing release's merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). **The introducing release itself is exempt** — the rule cannot fire on the release that ships it without creating a reflexive-pipeline loop, and this file carries the `allow-version-ref` marker for exactly this cutover clause. All releases that entered Stage 5 prior to the introducing release are also exempt.*

**Phase A (Agent):** A1 design scope assessment, A2 architecture alignment check, A3 blast radius analysis via [`release/tools/blast-radius.sh`](../../tools/blast-radius.sh) per [`release/references/protocols/blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) (transitive dependency mapping; manual `grep` deprecated for Stage 5), A4 design specification drafting (**A4's opening move when a design choice has ≥2 candidate approaches: run the design-exploration protocol per [`design-exploration.md`](../standards/design-exploration.md) — divergent generation → convergent narrowing → trade-off matrix, BEFORE specifying the surviving approach out and BEFORE the trade-off matrix is scored; omitted with a one-line rationale when the design has a single forced approach** — then) exact structure/naming/layout + Mode 3 implementability + Mode 4 debt flags + **A4.1 cascade-completeness sweep per § 5.6**), A5 ADR drafting as GitHub Issues with `adr` label.

**Phase A1.5 — Canonical-surface enumeration + cross-repo-citation translation (rides A1 scope-assessment).** A work item declares its affected files, but a declared reference is not always the file's canonical governed home: it may be a **substrate-level affected file** — a lower-level or migration-artifact pointer rather than the canonical surface that governs the content. Two substrate shapes recur, and A1.5 resolves both before design begins:

1. **Cross-repo citation translation.** An `originally #NNN` marker is a public-flip migration artifact — the number was meaningful in the pre-flip source repository and survives as provenance, so the local `#NNN` may or may not resolve to a live issue in this repository. It is a **cross-repo citation to be translated, never a surface to be edited.** The spoke translates each `originally #NNN` / cross-repo citation into its canonical in-repo governed home and records the translation (and its basis) in the Stage-5 output, so the Engineering spoke edits the canonical surface by construction rather than chasing a migration pointer.
2. **Body-level raw-path substrate.** A path named in the issue body prose points at where content is *observed*, not necessarily at the canonical surface that *governs* it. The spoke enumerates the canonical governed home for each affected file and designs the remediation against that home.

**The rule this step enforces — canonical-spec edit wins over substrate-body mutation** (per the substrate-vs-canonical precedent, ADR-062: a canonical-spec edit at the file's governed home takes precedence over mutating a substrate citation or the issue body): the remediation target is always the canonical governed home; a substrate reference is a pointer to be translated, not a surface to be edited; and the **issue body remains historical record** — the spoke does NOT rewrite the body to "fix" a stale or substrate-level citation (the body is directional, not authoritative; the canonical corpus is authoritative). When a declared affected file resolves to a canonical home different from its cited substrate path, the enumeration surfaces the divergence at scope-assessment time rather than after the Engineering rewrite is built. *Cutover (reflexive, per ADR-062): applies to releases entering Stage 5 strictly AFTER the introducing release's merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>); the introducing release is itself exempt, and this file carries the `allow-version-ref` marker for this cutover clause.*

**D-D — design-exploration before the trade-off matrix (the instruction surface).** The "invoke design-exploration before the trade-off matrix" instruction lives HERE — the Phase A4 spec is the de-facto Stage-5 instruction surface (the Principal Engineer persona runs as a hub-spoke driven by this spec; there is no separate solutioning skill to carry the instruction). When a Phase A4 design choice carries two or more candidate approaches, the spoke runs the design-exploration protocol (generation → narrowing → matrix) before scoring the trade-off matrix and before specifying the surviving approach. The protocol satisfies the design-review checklist's ≥3-alternatives check by construction rather than by retrofit. This instruction is mirrored into the Stage-5 chip pattern in [`hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) so spawned spokes carry it.

**Phase A3.2 — Doc-corpus-reorg ref-form enumeration (conditional).** When the change under design **moves or renames at least one durable-corpus file** (a doc-corpus reorg — relocation across directories, a directory rename, or a module-subtree move), the spoke MUST emit the complete ref-form enumeration per [`doc-corpus-reorg-ref-forms.md`](../protocols/doc-corpus-reorg-ref-forms.md): a table covering all six canonical ref-forms (F1 module-rooted literal · F2 relative-inbound · F3 root-escape · F4 mover-internal-outbound · F5 retained-sibling→mover · F6 governed mirror-pair), each with its sweep command, per-occurrence disposition (REWRITE / N/A / MIRROR-SYNC), and a verdict line. This makes the Engineering rewrite **complete-by-construction**: the exit gate (Phase B [`design-review-checklist.md`](../templates/design-review-checklist.md) Section 1 + Collective Review) **confirms** the six-form table is present and grounded, rather than discovering missed forms after the rewrite is built. The sub-step does NOT fire for in-place content edits (no path change) — omission when no file moves is the correct non-ceremony signal per [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) G2. `blast-radius.sh` (A3) remains the inbound-discovery tool for static targets; A3.2 covers the orthogonal moving-set rewrite surface it cannot reach (mover-outbound, root-escape past the module boundary, mirror byte-identity).

**Phase A3.1 — Impact-analysis method selection (domain-aware).** The A3 mandate above runs `blast-radius.sh`, a doc-corpus inbound-reference tracer (markdown/sh/json/yml/toml path-string fan-out — it has no model of a code module's import graph, a UI component dependency tree, or a platform solution-component dependency). For a deliverable whose domain is not the doc/governance corpus, that tracer returns a structurally-inapplicable signal. A3.1 makes the A3 impact-analysis *method* selectable by the deliverable's domain, while preserving the markdown-tree tracer as the unconditional default for doc/governance/pipeline-internal work. The selector branches on the **`domain:` class field** — the mandatory substrate authored on the `domain_practice` label at Stage 4 Phase A1.5 (the same single field the domain-guide index in § 5.7 reads; see the Stage 4 Planning spec's Domain-Best-Practice Sourcing-or-Flag Step for the field's schema and its A3-time File-Change-Matrix classification). The spoke does NOT re-derive the domain signal here — it reads the class already classified at Planning A3 from the File-Change-Matrix. The branch is on this abstract class, never a hard PROJECT.md read.

| Deliverable domain (`domain:` class field) | Impact-analysis method (Phase A3) | Authority |
|---|---|---|
| **doc / governance / pipeline-internal** (`domain: governance` and the doc-corpus classes) | **`blast-radius.sh` markdown-tree fan-out — DEFAULT, unchanged.** The A3 mandate above stands verbatim; this row is a no-op that preserves current behavior. | Mandatory (current behavior preserved) |
| **code / software** (`domain: software`) | **Code import-graph fan-out** — trace the changed symbol/module's importers transitively (language-native: `grep`/ripgrep on `import` / `require` / `from … import` / `#include`, or a language toolchain's dependency graph where one is available). Worked example in [`blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) § 12. | Method defined; tool deferred (opt-out record until a code-fan-out CLI ships) |
| **component / UI** (`domain: web` and component-class deliverables) | **Component dependency-tree fan-out** — trace which components import or mount the changed component via the framework's own dependency graph. | Method defined; tool deferred |
| **solution / platform-config** (`domain: enterprise-platform` and platform-solution deliverables) | **Solution-component graph fan-out** — trace solution-component dependencies via the platform's own dependency export. | Method defined; tool deferred |
| **any domain, no instrument available at design time** | **Documented opt-out record** — record the domain class, why `blast-radius.sh` is structurally inapplicable, and the manual fan-out actually performed. Record format + homing in [`blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) § 12. | Opt-out path |

**Default preservation (the no-regression guarantee).** For doc/governance/pipeline-internal deliverables the first row is a no-op: the A3 `blast-radius.sh` mandate is untouched and the markdown-tree tracer remains mandatory. A3.1 only *adds* method branches for non-doc domains; it cannot degrade the existing path. This release is itself a pipeline-internal/governance release → it takes the DEFAULT row → its own Stage-5 A3 (the reflexive blast-radius run in this output's Evidence) is unaffected.

**Within-A3 opt-out (design-still-happens) — distinct from the whole-issue `SKIP` token.** When a non-doc deliverable has no domain-appropriate instrument at design time, the spoke records the opt-out per § 12 and performs the fan-out manually. This is NOT the whole-issue `SKIP` token from the mixed-routing protocol: `SKIP` removes an issue from Stage 5 entirely (no design at all), whereas the A3.1 opt-out keeps the issue IN Stage 5 — A3 fires, design happens, and only the markdown *instrument* is swapped for a domain-appropriate fan-out. An opt-out record without a performed fan-out (no command and no manual-trace description) is an incomplete A3, not a valid opt-out, and fails the Section 1 exit gate in [`design-review-checklist.md`](../templates/design-review-checklist.md). The impact-classification tiers (Cosmetic ≤1 / Behavioral 2–5 / Structural ≥6-or-critical) from [`blast-radius-protocol.md`](../protocols/blast-radius-protocol.md) § 5 are domain-agnostic and apply to every method — only the fan-out discovery mechanism is domain-specific.

**Cutover (introducing-release-exempt):** the domain-aware A3 method-selector applies to releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). **The introducing release itself is exempt** (reflexive-pipeline-loop discipline — this release is itself a pipeline-internal/governance release, so its own Stage-5 A3 takes the markdown-tree DEFAULT row; this output's Evidence-section blast-radius run on `stage-05-solutioning.md` IS that proof). All releases that entered Stage 5 prior to the introducing release are also exempt.

**Phase A6 — Design-artifact production (when applicable per [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 7):** For each Tier-A activated artifact identified at A1 scope-assessment, produce the artifact per the per-flow-class tool selection in [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 6. Declare activated artifacts in the release plan's "Tier-A activated design artifacts" section (consumed by Stage 13 G-CL6 detection). Cutover per [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 11: applies to releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA recorded in [`<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). **The introducing release itself is exempt** (reflexive-pipeline-loop discipline — its Stage 5 sub-task IS the Stage 5 output where this discipline would apply).

**Phase A6.5 — Independent Adversarial Design Review (per the adversarial review protocol):** After Phase A6 design-artifact production completes AND BEFORE Phase B human review / Collective Review scope-lock, the hub launches an independent adversarial reviewer (`pmo-adversarial` agent) via the Agent tool per [`hub-spoke-bridge.md` Procedure 3 §Stage 5 Chip Pattern — Adversarial Design Review Discipline](../how-to/hub-spoke-bridge.md). Reviewer is **structurally independent** from the designing spoke (different `subagent_type` value → different session lifecycle → no shared session memory → no influence from designing-spoke context). Scope: **uniform** — every Stage 5 spoke output activates an adversarial review when Solutioning fires per Phase 0 Activation Gate (no per-issue selective routing).

Adversarial reviewer reads the Stage 5 spoke output comment + the parent issue body + sibling Stage 5 outputs in the same release, then produces **3 structured-list outputs** (Premise-Rejection-Findings + Failure-Mode-Findings + Counter-Design-Findings) per the schema below. Findings are **advisory** — Collective Review (next phase) consumes them as input to the Decision Briefing; the Operator weighs them at scope-lock decision time. Adversarial findings do not gate independently (gate authority belongs to Collective Review; cascading-blockers anti-pattern avoided per `review-composition-framework.md` § 4 AUTHORITY=advisory for this RC-* entry).

**Output schema (full):**

```markdown
## Adversarial Design Review — #N Stage 5 Output

### Premise-Rejection-Findings
For each premise challenged:
- **Premise (verbatim from Stage 5 spoke output):** <quoted text>
- **C3 classification per `triage-design-rereview.md` § 3:** <PT-1/PT-2/PT-3/PT-4>
- **Counter-evidence (concrete):** <file:line citation + observed value>
- **Severity:** Blocker / Major / Minor

### Failure-Mode-Findings
For each failure mode identified (per `failure-mode-standard.md` 5-field template):
- **Signature:** <one-line failure pattern>
- **Category:** TRIG | INPUT | PROC | OUT | HAND
- **Conditional:** Do NOT do X when Y, because Z
- **Root cause:** [systemic pattern] → [proximal cause] → [observable signal] per `review-discipline-principles.md` § 2
- **Mitigation:** <specific design change>
- **Principal-vs-junior response:** <how a principal would handle this>

### Counter-Design-Findings
For each counter-design proposed:
- **Spoke-recommended design:** <one-line summary>
- **Counter-design:** <alternative architecture>
- **Trade-off matrix:** Reversibility (CHEAP/MODERATE/EXPENSIVE) × Confidence (HIGH/MED/LOW) × Blast radius × Upstream-compat
- **Why this counter-design might prevail:** <evidence-cited justification>
- **Severity:** Blocker / Major / Minor

### Summary verdict
- **Total findings:** N premise-rejection + M failure-mode + P counter-design
- **Aggregate severity:** Blocker / Major / Minor / Cosmetic
- **CR consumption hint:** advisory hint — CR decides
```

Registered as `RC-5-adversarial-design-review` in [`review-composition-framework.md § 3`](../../../core/standards/review-composition-framework.md) Catalog (7-dim tuple: Stage 5 / output / adversarial / substantive / risk + correctness + reversibility / findings / advisory) and the § 4 Map cell at Stage 5 × Adversarial. The Map cell update disambiguates from the prior internal-spoke ceremony entry (`decision-discipline.md` M2 Opposing View remains the within-spoke ceremony; `RC-5-adversarial-design-review` is the independent-reviewer counterpart).

**Cutover discipline:** Applies to all releases going forward.

**Phase B (Human):** Accept/redirect/escalate per ADR. Approve Solutioning output or return to Planning if unworkable. Use [`release/references/templates/design-review-checklist.md`](../templates/design-review-checklist.md) as the structured review surface (Sections 1–5 self-reviewed by spoke; Section 6 operator sign-off). For concept ownership of the peer specs Stage 5 reads (M1/M2/M3, D-Gate, gate criteria, re-review schema, etc.), see [`architecture-overview.md § Peer-Spec Concept Ownership`](../../../core/disciplines/architecture-overview.md#peer-spec-concept-ownership).

**Dependencies-field AC refinement (conditional):** When AC refinement touches the body Dependencies field (rare; per [`ticket-information-architecture.md` Agent Write Permissions](../specs/ticket-information-architecture.md#agent-write-permissions) Stage 5 row), re-trigger the Stage 2 A3.5 native-dep mirror logic for the affected issue so native `blocked-by` stays consistent with the refined body. Per [`ticket-information-architecture.md § Native Dependencies — Mirror Trigger Points`](../specs/ticket-information-architecture.md#native-dependencies). Cutover: applies to releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA; **the introducing release itself exempt** (reflexive-pipeline-loop discipline).

**Ticket lifecycle:** Claim: validate Stage>=4-Planning, set Stage→5-Solutioning. Execute: design analysis + ADR drafting (A1-A5 + B approval). Resolve: post design review comment, refine AC in body if needed, close accepted ADRs. No status change. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md) Ticket Lifecycle Protocol.

**Framework dimensions touched:** Work Breakdown (refined change specs); Assignment (Principal Engineer persona); Handoff (ADR + Collective Review). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 5.7 Domain-Best-Practice Sourcing Step (Stage 5 Refinement)

When Stage 5 Solutioning is activated (per the Phase 0 Activation Gate), the design spoke inherits the `domain_practice` provenance label authored at Stage 4 Phase A1.5 — the inlined Mode A / Mode B label schema lives in the Stage 4 Planning spec's Domain-Best-Practice Sourcing-or-Flag Step.

**Stage 5 refinement obligation:** If Stage 4 emitted `Mode B — UNSOURCED-DOMAIN`, Stage 5 SHOULD attempt to upgrade to Mode A — design refinement is the natural surface to source authoritative guidance when the design exposes specific concepts whose external best-practice can be cited. Upgrade mechanism:

1. Identify the specific design concepts whose external best-practice would inform the design (e.g., "an enterprise platform's ALM solution-publishing pipeline" — a named concept that maps to authoritative documentation).
2. Cite authoritative sources for those concepts in the Stage 5 design spec; mirror the citations into the `domain_practice` label by REPLACING `source: UNSOURCED-DOMAIN` with the cited source list; update the `date` field.
3. Record the Mode-B → Mode-A upgrade in the release plan deviation log.

**Stage 5 carry-forward obligation (when no upgrade is possible):** When Stage 5 design proceeds without sourcing (the design genuinely does not depend on external practice OR the authoritative source is not accessible at design time), the `domain_practice` label travels UNCHANGED from Stage 4 into the Stage 5 design output. Stage 7 Dev Testing verifies presence + dated field on whatever label form lands.

**Domain-guide index (consumes the `domain:` class field).** When sourcing, the design spoke consults the domain-best-practice guide for the deliverable's domain — `core/standards/domain-best-practices/<domain>.md`, where `<domain>` is the value of the `domain:` class field on the `domain_practice` label (the substrate authored at Stage 4 Phase A1.5) — where such a guide exists. The guide's Applicability Profile `APPLIES-WHEN` confirms the guide fits the deliverable, and its `CONTRAINDICATED-WHEN` scopes the guidance to the deliverable's context (e.g., the governance guide's CI-3 keeps research-grade-audit practices from being imposed on an internally-governed deliverable). This composes §5.7's provenance label with the new guide index without duplicating either: the label carries the `domain:` signal; the guide carries the design-consumption content (what to check the design against) — distinct from the platform source-taxonomy, which is the sourcing input (which authoritative source to cite). When no guide exists for the deliverable's domain, that absence is itself the demand signal for authoring one (the SHIP-WITH-FLAG expansion path), and the design proceeds on the carry-forward obligation above.

**Domain-best-practice review-criterion interplay (forward-note).** The Stage-5/7 domain-best-practice **review criterion** — the sibling milestone work that adds a domain-practice review dimension to the design-review checklist and Stage-7 Dev-Testing — consumes a guide's Applicability Profile contraindications (the applicability-framework Contraindication Catalog IDs, CI-*) against the deliverable's domain, to assess whether the design respects the domain's authoritative practice. That review criterion designs its own wiring at its own Stage 5; this note states the interplay on the shared file without the design-exploration/guide work reaching into the review-criterion's scope.

**Cascade-Sweep applicability:** Updates to the `domain_practice` label's `source` or `date` field at Stage 5 are NOT cascade-completeness triggers per § 5.6 — the label appears once per release plan, not many times, so no cross-file sweep is required. (T1/T2/T3 triggers in § 5.6 fire on multi-file count / enumeration / threshold changes; the provenance label is single-occurrence.)

**Composition with R1 Evidence-Grounding:** When Stage 5 refines `domain_practice` from Mode B to Mode A, the cited sources may also serve as R1 Evidence-Grounding evidence per the Evidence-Grounding standard. The two disciplines are independent: R1 grounds canonicalizations of internal conventions; the domain-practice label grounds claims about external domain best-practice. Both may apply to the same design spec; neither replaces the other.

## 5.5 Forecast Discipline (Deploy-Resolution Claims)

*Applies to releases entering Stage 5 on or after this discipline's cutover effective date recorded in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`.*

Stage 5 spokes may include forecasts of how Stage 12 / 13 deploy actions will resolve open findings (e.g., `deploy.sh --check` warn-mode findings). Such forecasts MUST distinguish:

**Content-resolving deploy effects** — deploy resolves these:
- Check 1 (skill install-copy sync)
- Check 2 (package sync)
- Check 7 (package freshness)
- Check 12 (user-local mirror sync)
- Any check inspecting file content via byte comparison against the source tree

**History-resolving deploy effects** — deploy does NOT resolve these; require a subsequent commit OR an exemption-list entry:
- Check 8 (canonical-session-path freshness — inspects commit metadata)
- Check 10 (editor audit-trail trailer — inspects last non-merge commit's trailer)
- Any check inspecting commit metadata, message bodies, trailers, or session history

**Forecast format for history-level findings.** A Stage 5 forecast addressing a history-level finding MUST forecast one of:
1. **Resolves via subsequent `pmo-skill-editor` Mode A commit** carrying the required trailer at Stage 6 — when a code change is in scope and pmo-skill-editor invocation produces the trailer naturally.
2. **Resolves via `core/config/allowlists/skill-editor-exemption-list.txt` addition** with operator-approved rationale — when the affected skill is genuinely exempt (e.g., documentation-only patches that do not change skill behavior).

A forecast asserting "resolves at Stage 12 via `core/deploy/deploy.sh --deploy <skill>`" for a history-level check is a **misforecast**. Misforecasts surface as Stage 12 Tier 1 deviations per [release-process.md § Inter-Stage Feedback Protocol](../../governance/release-process.md) and are tracked by Stage 7 DT.

## 5.6 Cascade-Completeness Sweep (Phase A4.1)

*Cutover: applies to releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA recorded in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`. **The introducing release itself is exempt** — the protocol shipping in a release cannot fire on its own Stage 5 authoring without creating a reflexive-pipeline loop. The introducing release's own Stage 5 outputs use pre-rule discipline. All releases that entered Stage 5 prior to the introducing release are also exempt.*

When a Stage 5 change spec includes a **count update**, **enumeration update**, or **threshold/version-narrative change** to any file listed in its affected-files matrix, the spec MUST include a `### Cascade-Sweep` block enumerating every occurrence of the OLD value across the affected (file × OLD-value) pairs in scope.

**Trigger conditions (rule fires when ANY hold):**

| # | Trigger | Examples |
|---|---|---|
| T1 | Numeric count update (cardinality change: N → M) | "20 custom skills" → "19 custom skills"; "(11)" → "(10)"; "4 without packages" → "3 without packages" |
| T2 | Enumerated list update (member added / removed / renamed) | implementer skill removed from an alphabetical per-module skills array (`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS`); new skill added to Tracked Skills |
| T3 | Threshold / version narrative reference change | "180-day window" → "90-day window"; "N=2" → "N=3"; "v1.02" cited narratively → "v1.07" |

**Trigger does NOT fire when:**

- Spec edits no counts / enumerations / thresholds (pure prose addition).
- Counts being added are NEW (no prior value to sweep).
- The value appears only in a verbatim historical snapshot inside a fenced code block AND is explicitly marked as historical (per-occurrence PRESERVE rationale required).

**Required `### Cascade-Sweep` block format (one row per (file × OLD-value × occurrence)):**

```markdown
### Cascade-Sweep (per § 5.6 cascade-completeness rule)

**Sweep command(s):**
- `grep -nE '<old-value-regex>' <file>` per (file × value) pair below

| File | OLD value | Line | Context | Disposition | Rationale |
|---|---|---|---|---|---|
| `<path>` | `<value>` | <N> | `<quoted line>` | UPDATE / PRESERVE / N/A | `<one-line reason>` |
| ... | ... | ... | ... | ... | ... |

**Sweep date:** `<YYYY-MM-DD>` at commit `<short SHA>`
**Sweep verdict:** <count of UPDATE rows> / <count of PRESERVE rows> / <count of N/A rows>
```

**Load-bearing test (spec is incomplete if ANY hold):**

- `### Cascade-Sweep` section omitted when a triggering update is in spec scope.
- Sweep command(s) line missing OR irreproducible (no `grep` invocation cited).
- Sweep table missing rows for OLD-value occurrences that appear in the affected files (verifiable: re-run the grep against the release branch — if grep returns matches the table does not enumerate, the spec is incomplete).
- Disposition column contains rows without rationale.
- Any row marked PRESERVE without an explicit reason naming the preservation rationale (e.g., "historical snapshot in an archived release plan — out of cascade scope").
- Any row marked N/A without an explicit reason (e.g., "value coincidentally matches OLD value but is unrelated semantic — `(20)` in line 47 references RFC 20, not skill count").

**Sweep scope (narrow — by design):**

- **File-scope:** ONLY the files in the spec's affected-files matrix. NOT "the whole codebase" — that is L5 (`pmo-qa-auditor` automation) territory if/when the L5 mechanism ships (deferred per the L5 mechanism scope).
- **Value-scope:** ONLY the specific OLD VALUE being changed by the spec (plus regex-derivative occurrences: "20" sweeps "20", "(20)", "20 custom", "twenty" if narratively used). NOT "all numbers anywhere in the file."

**Composition with existing R1 Evidence-Grounding (per evidence-grounding-standard.md):** When the spec already produces an Evidence-Grounding artifact (canonicalization of a convention per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md)), the `### Cascade-Sweep` block lives in the spec body alongside the `### Evidence-Grounding` block. The two are non-overlapping disciplines: R1 surveys CURRENT state of a convention before canonicalizing it; Cascade-Sweep surveys OLD-VALUE occurrences after a state change. Both may apply to the same spec; neither replaces the other.

**Forcing function:** [`design-review-checklist.md § Section 3.5`](../templates/design-review-checklist.md) Cascade-completeness sweep self-check at Phase A4 → A5 transition rejects incomplete sweep block (5 structural checks per § 5.6 schema). Section 3.5 is OMITTED entirely when no count / enumeration / threshold update is in spec scope (per `decision-discipline.md` G2 ceremony-management guard — omission IS the non-ceremony signal).

**Reference: failure-mode-standard.md entry.** The `### Cascade-omission at count update — PROC` entry in [`core/standards/failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) § Reorg / structure-change examples codifies the anti-pattern this section prevents, with a prior release's DT findings as worked example (originating evidence: 2 Tier 1 [ADJUST] findings from one 20→19 cascade where adjacent occurrences were missed in already-touched files).

## 6. Outputs
Design specifications (refined change specs), ADR issues (GitHub Issues with `adr` label — closed when accepted), blast radius analysis, updated release plan on release branch, skip rationale (when skipped). Design artifacts (when Tier-A activation fires per [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 7).

Stage 5 sub-task output comments follow the canonical 7-section H3 frame and 4 required H2 content buckets (Design Decisions / Blast Radius / Feasibility Assessment / ADR Pointers) defined in [`solutioning-output-template.md`](../standards/solutioning-output-template.md). The template includes the literal copy-paste scaffold and composition rules for R1 Evidence-Grounding (per evidence-grounding-standard.md), Tier-A design-artifact declaration (per [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 7), and the Stage 5→6 boundary contract. The template's `## Blast Radius` bucket also carries the **frozen-spec prose–artifact precision** rule (required-when-triggered) — `### Summary` and restated Acceptance-Criteria prose must cite the File Change Matrix's exact quantities/enums verbatim (or carry a `[DEFERRED — <rationale>]` label), so Dev Testing and QA verify against one internally-consistent surface rather than re-adjudicating a drifted figure.

**Date-variable discipline (per date-variable-convention.md):** When a Stage 5 spec creates ≥1 downstream load-bearing identifier carrying a date in `YYYY-MM-DD` form (audit-folder paths, AC verifier identifiers, ADR source-observation references), the spec MUST include a `### Date Variable` block per [`core/standards/date-variable-convention.md`](../../../core/standards/date-variable-convention.md). Variable `${AUDIT_DATE_UTC}` resolves at Stage 6 first commit via `date -u +%Y-%m-%d`. Engineering propagates the resolved value consistently across all artifacts in the release. Stage 5 output that hardcodes literal dates in load-bearing positions when the trigger predicate holds is incomplete; Collective Review flags as a structural defect.

**Reference-durability discipline (per the reference-durability standard under the core standards set):** A Stage 5 spec is itself a durable design artifact, and any durable-corpus file it directs Engineering to author or edit is governed by the reference-durability standard. State rules unconditionally and inline, summarize referenced content rather than linking to it, and confine any unavoidable bare issue reference to a designated reference block with an inline summary; do not introduce a version-cutover clause into durable rule text. The reference-durability hook, deploy-check check, and CI workflow enforce this at commit and PR time. A spec that bakes a fragile reference into the durable content it specifies is incomplete; Collective Review flags it.

For the structured boundary contract, see [schemas/stage-io-contracts.md](../../../core/schemas/stage-io-contracts.md#boundary-stage-5--stage-6).

**Canonical-form applicability (per the canonical-form-application discipline under the core disciplines set):** Stage 5 produces a canonical-form-framed artifact — the ADR. When this stage authors an ADR, produce it in its canonical form (the markdown-ADR convention) OR document partial-form conformance with explicit rationale per the application protocol; do not silently leave the canonical form partial-or-absent. The frame registry and the produce-OR-document-partial protocol live in the canonical-form-application discipline.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all issues have design specs, ADRs resolved (closed), blast radius complete, no unresolved questions, plan updated, Mode 3/4 flags resolved; incoming deferred items accounted (every item whose Target stage = this stage, per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md), is picked up or re-deferred with rationale — zero unaccounted incoming deferrals).
Judgment (1-5): design specificity, architecture alignment, blast radius coverage, decision quality, handoff completeness.
Calibration: design specs vs. actual implementation, ADR decisions vs. outcomes, blast radius predicted vs. actual, escape rate.

### 7.1 Methodology-Design Gate Criteria (analysis-class deliverables)

*Per [ADR-011](../../ADRs/ADR-011-analysis-class-methodology-design-treatment.md) — the gate-teeth for the Stage 5 Research-Methodology Design variant ([`release-personas.md` § Stage 5 Variant](../specs/release-personas.md)). A `per-stage-shard-standard.md § 4.1` MODIFY (new gate criterion on an existing stage), NOT a new stage. These criteria SUPPLEMENT § 7's base metrics; they do not replace them.*

**Conditional-fire predicate:** This criteria set fires ONLY when the Stage 5 Research-Methodology Design variant activated for the release deliverable (an analysis-class research artifact — audit, gap analysis, methodology design — surfaced by T3 / T4 per [`planning-solutioning-handoff.md` § 3](../../../core/standards/planning-solutioning-handoff.md)). For code/governance releases the variant does not activate and § 7.1 is not exercised (the base § 7 criteria remain unconditional). Omission of § 7.1 evaluation when the variant did not activate is the correct non-ceremony signal per [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) G2.

**Gate criteria (ALL must hold to authorize Engineering for an analysis-class deliverable):**

| # | Criterion | Method | Authority |
|---|---|---|---|
| MD-G1 | Research methodology specified as an executable artifact — sampling frame / unit of analysis, evidence-grading rubric, coding scheme, and analysis plan are each present and implementation-ready (not "make it rigorous") | Inspect the Stage 5 output: each of the 4 elements has concrete, non-placeholder content | Gate-blocking |
| MD-G2 | Validity threats named with mitigations BEFORE findings — selection bias, coverage gaps, and reproducibility are each addressed | Inspect the Stage 5 output's validity-threats block; reject if findings precede the threats block | Gate-blocking |
| MD-G3 | Methodology grounded in cited prior art per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) — every canonicalized methodology choice carries a current-state survey + canonical-choice justification | Re-run the cited survey command(s); confirm each methodology canonicalization has the 2-part Evidence-Grounding schema | Gate-blocking |
| MD-G4 | Stage 5→6 methodology handoff schema (§ 12) populated — Engineering receives an executable methodology, not a research direction | Confirm the § 12 handoff block is present and all required fields are non-empty | Gate-blocking |
| MD-G5 | Evidence-quality bar declared — the minimum evidence grade required for a finding to be load-bearing is stated, matching the persona-stretch instance precedent that produced an explicit evidence-quality bar | Inspect for a declared evidence-quality threshold (e.g., grading rubric + minimum-grade rule) | Gate-blocking |

**Why gate-blocking (not advisory):** the audit's pre-registered Option-B-insufficiency note ("Option B may be insufficient if the structural distinction warrants its own gate criteria + hand-off schema") and the adversarial design review's gate-teeth finding establish that methodology-design needs teeth, not vocabulary. Per ADR-011 § Decision, these criteria carry the same gate authority as § 7's base metrics for analysis-class deliverables — a methodology that fails MD-G1..G5 returns to Solutioning, it does not proceed to Engineering on advisory grounds.

These criteria apply when the Research-Methodology Design variant activates; a code or governance release does not exercise them.

## 8. Automation Level
Overall Tier 2. Today: agent runs A1-A5 in conversation. Target: Principal Engineer skill (Modes 1-4) auto-generates design analysis from release plan.

## 9. Gap Summary
10 gaps identified. Key items: mixed per-issue routing future state (P3), the documentation best-practice review (P2).

## 10. Retro
Key lessons: an early documentation release should have activated Solutioning — one of its issues triggered "new file with non-trivial content." All of that release's decisions had single reasonable approaches — no ADRs needed (expected for a doc release). Blast radius was bounded for it. Mode 3/4 secondary checks added value. Documentation practices need systematic review across all stages.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `decision` | `adr-opened` / `adr-closed` | ADR issue opened or closed during per-issue Solutioning (when D-class items require explicit ADR per [`decision-discipline.md` § 3](../../../core/disciplines/decision-discipline.md)) | `spoke:#N` (Solutioning spoke) |
| `escalation` | `tier-0` | Phase 0.5 re-review fires Tier 0 Premise Rejection (C3 classification) per [`triage-design-rereview.md` § 9](../standards/triage-design-rereview.md) | `spoke:#N` |
| `re-review` | `phase-0.5-row` | Phase 0.5 re-review row appended to `triage-design-rereview-instrumentation.md`; payload carries `projects_to: triage-design-rereview-instrumentation.md:<row-anchor>` | `spoke:#N` |
| `decision` | `scope-lock` | Collective Review scope-lock decision rendered (approve / adjust / reject) — see § Release-Level Checkpoint below | `operator` |
| `decision` | `cross-d-upstream-compat` | Cross-D upstream-compatibility scan surfaces a `**CONFLICT.**` signal during Collective Review per § Process bullet 5 | `hub` |
| `decision` | `cascade-sweep-block` | Stage 5 spec includes a `### Cascade-Sweep` block per § 5.6 (cascade-completeness rule); payload carries `triggers: [T1\|T2\|T3]`, `files_swept: <N>`, `old_values: <N>`, `verdict: <UPDATE>/<PRESERVE>/<N/A>` | `spoke:#N` |

Cutover: events occurring on or after the FIRST release entering this stage strictly AFTER this protocol's introducing-release merge SHA. The introducing release itself: exempt (reflexive-pipeline-loop discipline). The `cascade-sweep-block` subtype is additionally bounded by the § 5.6 rule cutover (its introducing release self-exempt).

## Release-Level Checkpoint: Collective Review

**Trigger:** All of the following are true:
- Release has ≥2 issues with Solutioning activated (per Stage 4 applicability matrix)
- All applicable Solutioning sub-tasks are closed

**Does not fire when:** Release has 0-1 Solutioning-activated issues (per-spoke Procedure 4 handling is sufficient) or Solutioning was skipped for the entire release.

**Purpose:** Validate cross-issue design coherence before authorizing Engineering. Individual Solutioning spokes resolve design decisions per-issue; the collective review evaluates the set as a coherent unit — checking for conflicting designs, unresolved cross-dependencies, and cumulative risk.

**Process:**
1. Hub produces a consolidated Decision Briefing covering all Solutioning outputs:
   - Cross-issue dependency satisfaction (all directional dependencies resolved)
   - Design conflict detection (competing approaches to shared files or patterns)
   - Cumulative risk assessment (aggregate blast radius, compounding risks)
   - Scope confirmation (release scope still valid after Solutioning discoveries)
   - **Cross-*release* coherence (concurrent release set):** the hub reads this release's standing `## Parallelization Map` structural-blast-radius (Tier-S) verdict (per the Stage 3 Bundle spec § A9.6.1 axis) AND every concurrently-active sibling release's map, and confirms no concurrent release sits in this release's structural surface `SURFACE(R)` — or this release in a sibling's — unacknowledged. This extends the checkpoint from cross-*issue* coherence (within one release) to cross-*release* coherence (the in-flight set), so a structural collision that carries no ticket-dependency edge and no same-path overlap is surfaced at scope-lock rather than discovered mid-pipeline. For a single-issue release the ≥2-Solutioning-activated trigger does not fire; this row is then authored as part of per-spoke Procedure 4 handling and recorded in the durable Parallelization Map, not as a new ceremony. **Cutover:** applies to releases entering Stage 5 strictly AFTER this protocol's introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline).
2. Operator reviews the briefing and renders a scope lock decision:
   - **Approve:** Scope locks. Engineering is authorized for all issues.
   - **Adjust:** Operator modifies scope (defer issue, add issue, re-sequence). Affected Solutioning sub-tasks may re-open.
   - **Reject:** Return to Solutioning for specific issues with identified deficiencies.

**Outputs:** Scope lock authorization (operator decision documented on release planning sub-task), engineering authorization for all issues in the release.

**Scope Lock Rules:**
- **Pre-lock (during Solutioning):** Scope is "soft locked" — hub-spoke Scope Control applies (no new issues without operator approval), but Solutioning discoveries can trigger scope discussions.
- **Post-lock (Engineering through Stage 9):** Scope is "hard locked." Override process:
  1. Engineering spoke discovers issue requiring scope change
  2. Spoke raises finding in its sub-task output "Evidence" section (does not self-authorize)
  3. Hub presents override request to operator via Decision Briefing: issue context, impact on existing designs, impact on release timeline, recommendation (add vs. defer)
  4. Operator decides: add to release with impact re-assessment, or defer to next release
  5. Decision documented on release planning sub-task with: issue number, rationale, impact assessment, operator decision, date
- Override is governed, not forbidden. The goal is traceability, not rigidity.

**Relationship to Stage 9 (Plan Review):** Not redundant. The collective review asks "Are these designs coherent enough to start building?" at the Solutioning→Engineering boundary (Stage 5→6). Stage 9 asks "Is this release safe to deploy?" at the QA→Execute boundary (Stage 8→12). Stage 9 cannot catch design incoherence — by the time it fires, conflicting designs have already been engineered. The collective review prevents that waste.

**Relationship to issue-level gates:** The collective review is release-scoped (evaluates the set of issues) and fires at the Stage 5→6 boundary. It is architecturally distinct from issue-level gates at Stages 1-3 (per gate-criteria-spec.md), which govern individual issue progression through early pipeline stages. For the issue-level gate model, see Stage 3 gate criteria.

> For the operating procedure, see `release/governance/release-process.md` Collective Review Protocol (Post-Solutioning).

## 12. Methodology-Design Handoff Schema (Stage 5→6, analysis-class deliverables)

*Extended-protocol H2 owned by Stage 5, per [`per-stage-shard-standard.md` § 4.1](../../../core/standards/per-stage-shard-standard.md) ("new cross-stage protocol owned by an existing stage → append as extended-protocol H2 after § 11") and § 3.2. This is the **gate-teeth handoff schema** for the Stage 5 Research-Methodology Design variant ([`release-personas.md` § Stage 5 Variant](../specs/release-personas.md)), pre-registered by [ADR-011](../../ADRs/ADR-011-analysis-class-methodology-design-treatment.md) — a MODIFY of the Stage 5 surface, NOT a new stage. It composes WITH the general Stage 5→6 boundary contract at [`schemas/stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md#boundary-stage-5--stage-6); it does not replace it.*

**When this schema is produced:** ONLY when the Research-Methodology Design variant activated for the release deliverable (analysis-class research artifact surfaced by T3 / T4 per [`planning-solutioning-handoff.md` § 3](../../../core/standards/planning-solutioning-handoff.md)). For code/governance releases the variant does not activate and this schema is omitted (omission IS the non-ceremony signal per [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) G2). Gate criterion MD-G4 (§ 7.1) is the forcing function — a missing or under-populated handoff block blocks the Stage 5→6 transition for an analysis-class deliverable.

**Why a dedicated handoff schema (not the general boundary contract alone):** the actual persona-stretch instance produced explicit handoff schemas + an evidence-quality bar; the audit pre-registered that Option B would be insufficient if the structural distinction warranted "its own gate criteria + hand-off schema," and the adversarial design review confirmed the vocabulary-only variant under-powered. This schema gives methodology design the executable-handoff teeth so Engineering receives a runnable methodology, not a research direction.

**Required handoff block (Stage 5 output → Stage 6 input):**

```markdown
### Methodology-Design Handoff (Stage 5→6, per stage-05-solutioning.md § 12)

**Deliverable class:** analysis-class research artifact (audit | gap-analysis | methodology-design)
**Activating triggers:** T3 (structural-design) and/or T4 (multiple-approaches) — cite the issue + body framing
**ADR:** <ADR-NNN reference for the methodology decision, if a canonicalization-class choice was made>

**Sampling frame / unit of analysis:** <what is sampled, the population, inclusion/exclusion rules, N or coverage target>
**Evidence-grading rubric:** <grades + the criteria per grade; the minimum grade for a finding to be load-bearing (MD-G5 evidence-quality bar)>
**Coding scheme:** <categories / codes the analysis applies; how ambiguous cases are resolved>
**Analysis plan:** <step-by-step procedure Engineering executes; reproducible commands where applicable>
**Validity threats + mitigations:** <selection bias / coverage gaps / reproducibility — each with its mitigation, declared BEFORE findings per MD-G2>

**Evidence-Grounding pointers:** <links to the R1 current-state surveys backing each methodology canonicalization, per evidence-grounding-standard.md>
**Reproducibility note:** <whether the analysis is script-derived or hand-classified; the survey commands + baseline SHA so a re-run is byte-reproducible>
**Engineering executability check:** <one-line confirmation that Stage 6 can run the methodology as written without re-deriving research direction>
```

**Load-bearing test (handoff is incomplete if ANY hold):**

- The `### Methodology-Design Handoff` block is omitted when the variant activated.
- Any of the 5 methodology fields (sampling frame / evidence-grading rubric / coding scheme / analysis plan / validity threats) is empty or placeholder ("TBD", "make it rigorous").
- The evidence-grading rubric omits the minimum-grade-for-load-bearing-finding rule (MD-G5).
- Validity threats are listed AFTER findings rather than before (MD-G2 ordering).
- The reproducibility note omits the survey commands + baseline SHA when the analysis is script-derived.

This schema is produced when the Research-Methodology Design variant activates; a code or governance release omits it.

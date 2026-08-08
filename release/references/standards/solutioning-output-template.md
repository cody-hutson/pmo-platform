<!-- reference-durability: allow-link -->
---
title: Solutioning Output Template
purpose: K1 codified-knowledge canonical template for Stage 5 Solutioning sub-task output comments — defines the 7-section H3 comment frame, the 4 required H2 content buckets (Design Decisions / Blast Radius / Feasibility Assessment / ADR Pointers), and composition seams with R1 Evidence-Grounding, Tier-A design-artifact declaration, and the Stage 5→6 boundary contract
type: standard
parallel_to: evidence-grounding-standard.md (R1 Evidence-Grounding consumer at the comment-frame composition seam), design-artifact-standard.md (Tier-A activation declaration consumer), planning-solutioning-handoff.md (sister K1 standard — Stage 4→5 ENTRY contract; this template owns OUTPUT contract), stage-io-contracts.md (Stage 5→6 boundary contract — this template's `### Output for Stage 6` block is the Stage 6 input)
reversibility: CHEAP (forward-only template; existing Stage 5 outputs not retroactively conformed; pre-cutover releases exempt; template scaffold revisable in subsequent releases without breaking existing outputs)
consumers: "release/governance/release-process.md Stage 5 § Outputs (cross-ref); release/references/pipeline/stage-05-solutioning.md § 6 Outputs (cross-ref); release/references/how-to/hub-spoke-bridge.md Procedure 3 Spoke Template (chip-prompt scaffold consumer); release/references/templates/design-review-checklist.md (Phase A4→A5 gate-check coverage future-scope); core/skills/pmo-qa-auditor/SKILL.md (audit-trail surface)"
---
<!-- repo-integrity: allow-issue-ref -->

# Solutioning Output Template — Stage 5 Sub-Task Output Scaffold

## § 1. Purpose + Scope

Defines the canonical structural template for Stage 5 Solutioning sub-task output comments — the GitHub Issue comments emitted by Stage 5 Solutioning spokes per [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) § 6 Outputs and routed via [`hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) Procedure 3.

This template is the OUTPUT CONTRACT counterpart to the ENTRY CONTRACT defined by [`planning-solutioning-handoff.md`](../../../core/standards/planning-solutioning-handoff.md) (sister authoring of the entry-contract standard). Together the two standards bracket the Stage 4→5→6 corridor: entry criteria + output scaffold.

**In scope (this standard):** Structural template for Stage 5 sub-task output comments (the comment frame + 4 required content buckets + composition seams + literal copy-paste scaffold).

**Out of scope (this standard, deferred per D-Scope (B)):** The broader per-stage documentation-protocol audit from the source ticket body Step 1 (audit each stage's output artifacts against available GitHub features and documentation best practices). If a follow-up issue surfaces, the audit may consume / extend this standard but does not retroactively modify it.

**Audience:** Stage 5 Solutioning spokes (primary producer); operator at Collective Review (primary consumer of conformance); pmo-qa-auditor (audit-trail consumer); Stage 6 Engineering spokes (consumer of `### Output for Stage 6` block).

## § 2. When This Applies

Applies to **every Stage 5 Solutioning sub-task output comment** posted by a Stage 5 spoke. One template instance per Stage 5 sub-task; one Stage 5 sub-task per per-issue Solutioning activation (per `pipeline/stage-05-solutioning.md` § 5 Phase 0 activation criteria + Stage 4 release plan § 6 Stage Applicability Matrix).

**Does NOT apply to:**

- Stage 4 Planning sub-task comments (see [`planning-solutioning-handoff.md`](../../../core/standards/planning-solutioning-handoff.md) for the Stage 4→5 ENTRY contract)
- Stage 6 Engineering sub-task comments (see Stage 6 spec in `pipeline/stage-06-engineering.md`)
- ADR issue bodies (see [`adr-issue-template`](../../../.github/ISSUE_TEMPLATE/adr.yml) if present, else standard issue body conventions)
- Collective Review Decision Briefing comments (see `release/governance/release-process.md` Collective Review Protocol; hub-authored, not Stage 5 spoke)
- Tier 0 Premise Rejection escalation comments (see [`triage-design-rereview.md`](triage-design-rereview.md) § 9 template)

**Cutover:** Applies to all Stage 5 Solutioning sub-task output comments going forward.

## § 3. The Comment Frame (7 H3 sections)

Every Stage 5 sub-task output comment carries one H2 header (the comment title) and 7 H3 sub-sections in this order:

| # | H3 section | Required | Purpose |
|---|---|---|---|
| 1 | `### Summary (30 seconds)` | YES | 2-4 sentence verdict — main decision, recommended path, blocker if any |
| 2 | `### Detail` | YES | The substantive design analysis — contains the 4 H4 content buckets specified in §§ Design Decisions / Blast Radius / Feasibility Assessment / ADR Pointers below |
| 3 | `### Evidence` | YES | Reproducible commands and source citations grounding the spec — file:line / `gh issue view` / `git log` / `grep` invocations |
| 4 | `### Evidence-Grounding (R1)` | CONDITIONAL — REQUIRED when canonicalizing per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md); OMIT when no canonicalization fires | 2-part artifact (current-state enumeration + canonical-choice justification + out-of-scope drift) per the standard's Schema |
| 5 | `### Tier-A Activated Design Artifacts` | CONDITIONAL — REQUIRED when Tier-A activation fires per [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 7; OMIT when no activation | Declaration table per the standard's activation matrix; Stage 13 G-CL6 reads this section |
| 6 | `### Decisions & Recommendations` | YES | Clean recap of recommended D-decision choices; operator-actionable; one row per recommendation with status (RECOMMENDED / OPTIONAL / DEFERRED) and Empirical Verification subsection (R3) |
| 7 | `### Output for Stage 6` | YES | File change spec — Edit-ready for Stage 6 Engineering. NEW / MODIFY / DELETE × path × intent × mechanism. Literal scaffold content for NEW files |

**Header H2 format:** `## Stage 5 Solutioning — v<X.Y>-<milestone-slug> (issue #N)` where `<X.Y>` is the release version and `<N>` is the parent issue number.

**Optional preamble** (between the H2 header and `### Summary`): persona / Stage 4 anchor / Stage 5 spec anchor / sister-issue note in bold field-prefix style. Pattern observed in prior Stage 5 spokes.

## Design Decisions

The `## Design Decisions` content bucket — emitted as `#### Design Decisions` H4 nested inside `### Detail` of the spoke output — captures each D-class architectural decision the spoke renders during Solutioning.

**Required elements per D-decision:**

| Element | Form | Notes |
|---|---|---|
| D-decision ID | `D-N` or release-plan D-name (e.g., D-Scope, D-DualWriteEmitSequence) | Use release-plan D-name when the decision is declared in the Stage 4 release plan's § 9 Operator Decision Gates; use `D-N` (numbered) for spoke-internal decisions |
| Options considered | ≥2 alternatives | Single-option D-decisions are NOT decisions; if only one option exists, document as "non-decision" inline and skip the D-record |
| Pros / Cons per option | One row per option in a sub-table | Asymmetric pros/cons indicate weak alternative — challenge the framing |
| Recommended choice | Boldface marker | Often `**RECOMMENDED**` or `**(N) — `<option-letter>` Foo`**`(SELECTED)`** |
| Rationale | Cite source (audit / upstream / ADR) | Must reference at least one of the 3 categories per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) justification criteria |
| Reversibility tier | CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE | Per CLAUDE.md universal preference (Reversibility discipline) |
| Confidence | HIGH / MEDIUM / LOW | Per CLAUDE.md universal preference |
| Upstream-compatibility check | Required when skill-authoring surface touched | Cite `upstream-reference-catalog.md` entry + last_verified_date staleness check (per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) and `release-process.md` Collective Review Cross-D scan) |

**Anti-patterns (failure modes — see § 6):**
- "Selected first solution" — no alternatives enumerated
- Missing reversibility/confidence
- Single-option D-records (not decisions)
- Generic rationale ("best practice" / "platform convention") without citation

**Cross-references:**
- [`adr-authoring-guide.md`](../../../core/standards/adr-authoring-guide.md) § When to write an ADR — ADR threshold (the when-to-write rubric)
- [`decision-discipline.md` § 3](../../../core/disciplines/decision-discipline.md) — M1/M2/M3 mechanisms
- [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) — anti-pattern catalog

## Blast Radius

The `## Blast Radius` content bucket — emitted as `#### Blast Radius` H4 nested inside `### Detail` of the spoke output — enumerates files, schemas, consumers affected by the proposed change.

**Required elements:**

| Element | Form | Notes |
|---|---|---|
| File change matrix | Table: file × intent (NEW / MODIFY / DELETE) × reversibility | Aligns with Stage 4 release plan § 7 File Change Matrix; refined per Stage 5 design decisions |
| Schema-level impact | Inline narrative or table | Identify whether schemas in [`core/schemas/`](../../../core/schemas/) are modified; cite affected schema files |
| Consumer enumeration | Table: consumer × reading surface × update needed? | Surface for R1 R4 N-way consistency scan at Collective Review |
| Cross-PR contention | Baseline-pinned audit per Stage 4 § 8 A4 | Reference Stage 4 audit; identify any incremental contention surfaced during Solutioning |
| Cross-release coordination | Table: coordination surface × status × action | Sister-issue alignment, peer-standard references, in-flight release awareness |
| Downstream cascade (Tier-A G-CL6) | Note Tier-A activation if fires | If `### Tier-A Activated Design Artifacts` § fires, briefly note G-CL6 refresh obligation here too |

**Composition with Stage 5 § 5.6 Cascade-completeness sweep:** If the spec includes a count / enumeration / threshold update (per § 5.6 T1 / T2 / T3), the `#### Blast Radius` section MUST include or reference a `### Cascade-Sweep` block. The Cascade-Sweep block can live in `### Detail` (as a sibling to `#### Blast Radius`) when the sweep is substantial, or inline within `#### Blast Radius` when the sweep is bounded (1-2 file × value pairs).

**Composition with the Phase A3.2 doc-corpus-reorg ref-form enumeration:** If the change moves or renames at least one durable-corpus file (a doc-corpus reorg), the `#### Blast Radius` section MUST include or reference the complete six-form ref-form table (F1–F6) produced at Phase A3.2 per the doc-corpus-reorg ref-form protocol. Like the Cascade-Sweep block, the ref-form table can live in `### Detail` as a sibling to `#### Blast Radius` when substantial, or inline when bounded. This fires on a path change (file move/rename); § 5.6 fires on a value change (count/enumeration/threshold) — the two are orthogonal triggers and a change can emit both.

**Required-when-triggered: BLOCK-DESTRUCTIVE-022 script-execution allowlist callout.** When the design introduces a **new in-tree bash CLI** — any executable `*.sh` script the platform will invoke via `bash <path>` / `sh <path>` / `source <path>` / `. <path>`, placed under `release/tools/`, `core/hooks/`, `core/deploy/`, or any other tracked location — the `#### Blast Radius` section MUST list the script's required `core/config/allowlists/script-execution-allowlist.txt` entries. The script-execution guard (rule ID **BLOCK-DESTRUCTIVE-022**) blocks any subprocess script execution whose path is not in that allowlist, so a new CLI that is not pre-allowlisted will be blocked at first invocation. The guard matches the literal path as it appears in the Bash command (glob `case` patterns, NOT regex; matched before `~` expansion), so the same script needs **all four invocation forms** allowlisted:

| # | Invocation form | Pattern shape (example for `release/tools/<script>.sh`) |
|---|---|---|
| 1 | Absolute workspace path | `[CLAUDE_WORKSPACE_ROOT]/.../release/tools/<script>.sh` |
| 2 | Worktree-glob path | `[CLAUDE_WORKSPACE_ROOT]/.claude/worktrees/*/release/tools/<script>.sh` |
| 3 | `./relative/path` form | `./release/tools/<script>.sh` |
| 4 | Bare `relative/path` form | `release/tools/<script>.sh` |

This is a **required-when-triggered** checklist row: it fires only when the design introduces a new in-tree bash CLI, and is OMITTED entirely (non-ceremony) when the change introduces no new executable script. When it fires, the four allowlist lines are part of the Stage 6 `### Output for Stage 6` file-change spec (a MODIFY of `core/config/allowlists/script-execution-allowlist.txt`) — they are not deferred to a follow-up release. The blast-radius CLI entries already in that allowlist are the worked example of all four forms.

**Coverage boundary of the guard cited above — four conditions.** BLOCK-DESTRUCTIVE-022 is enforced by a PreToolUse hook, and such a control is in force only when **all four** of these hold, and not when any one fails: (1) **loading** — the session resolved a settings surface that declares the hook wiring (it applies to any session, main or spawned, whose working directory is under the governed workspace root; a session resolving no such surface loads no hooks at all, and one outside the root is excluded by the scope guard); (2) **bypass** — `CLAUDE_HOOK_BYPASS` was not set in the launching environment (layer 1, which exits **both** hook classes, so the security/workflow asymmetry does **not** exist there); (3) **master-activation class** — a `security`-class hook always enforces, a `workflow`-class hook is inert while master activation is off; (4) **mode** — most block hooks warn-and-allow in warn mode, a minority are mode-independent. A citation naming fewer than four overstates the coverage. Canonical statement: [`subagent-security-posture.md` § 3.1](../../../core/standards/subagent-security-posture.md).

**Consequence for this checklist row, stated plainly:** allowlisting is required because an unallowlisted CLI is blocked *where the guard is in force* — **not** because allowlisting is what makes a script runnable. Do not write a design that treats the allowlist as the reason a script executes, and do not accept a residual sized against the assumption that this guard will catch an unallowlisted invocation without first checking all four conditions on the path that invocation will actually run on.

**Required-when-triggered: frozen-spec prose–artifact precision.** When a Stage 5 spec references a quantity or enumerated set that is *frozen* in the File Change Matrix or another frozen design artifact (a file count, a NEW/MODIFY/DELETE intent, an option-enum, a phase/gate count, a checklist-item count), the `### Summary` and any restated Acceptance-Criteria prose MUST cite that quantity/enum **verbatim** — the same number and the same enum labels the frozen artifact carries. Where the prose cannot yet match the frozen artifact (a value genuinely undecided at authoring time), state the divergence explicitly with a **labelled deferral** — `[DEFERRED — <one-line rationale>]` — rather than a silently rounded or approximated figure. **Why:** a summary/AC figure that drifts from the frozen artifact hands Dev Testing and QA (and Collective Review) *two* surfaces to reconcile, forcing a re-adjudication of which one is authoritative; holding the prose to the frozen artifact's exact quantities/enums keeps **one internally-consistent surface to verify against**, so downstream gates check the spec, not the spec against itself. This is a **required-when-triggered** checklist row: it fires only when the spec restates a frozen quantity/enum in its `### Summary` or restated AC, and is OMITTED (non-ceremony) when the spec carries no such restated frozen value.

**Anti-patterns:**
- File list without intent/reversibility columns
- Consumer enumeration omitted (R1 R4 N-way scan cannot run)
- Cross-PR contention check skipped when Stage 4 release plan declared in-flight overlap
- New in-tree bash CLI introduced but BLOCK-DESTRUCTIVE-022 allowlist entries omitted (or listed in fewer than all four invocation forms) — a partial form set leaves the un-listed invocation paths blocked wherever the guard is in force
- A control claimed on the strength of a PreToolUse hook (or an allowlist it reads) without stating its **four-condition** coverage boundary, or a residual sized against that guard without checking the four conditions on the path the work actually runs on
- `### Summary` or restated AC cites a rounded/approximate quantity or a paraphrased enum that drifts from the frozen File Change Matrix (e.g., "touches ~3 files" when the matrix freezes 4; "adds a config option" when the enum is a named 3-value set) — this hands Dev Testing / QA / Collective Review two surfaces to reconcile; cite the frozen figure verbatim or carry a `[DEFERRED — <rationale>]` label

## Feasibility Assessment

The `## Feasibility Assessment` content bucket — emitted as `#### Feasibility Assessment` H4 nested inside `### Detail` of the spoke output — validates implementability of the proposed change against current platform state.

**Required elements:**

| Element | Form | Notes |
|---|---|---|
| Mode 3 (implementability) flags | Inline narrative or bulleted list | Per [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) § 3 Persona table — Principal Eng Skill Mode 3 |
| Mode 4 (debt) flags | Inline narrative or bulleted list | Per same Mode 4 reference; flag tech-debt the spec creates or paid down |
| Cross-release coordination | Table: surface × status × action | Sister-issue conventions, peer-standard alignment, in-flight PR check |
| Testability | Verification commands (grep / file-presence / behavioral check) | Aligns with Stage 4 release plan § 13 Verification Plan AC# rows; spoke refines per-spec |
| Rollback feasibility | Reversibility tier + mechanism | `git revert` for content-only; deploy reverse for skill changes; partial-ship safe? |

**Anti-patterns:**
- Mode 3 flags omitted when blast radius non-trivial
- Testability claim without verification command
- "Rollback safe" assertion without mechanism

**Cross-references:**
- [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) — Mode 3/4 framework
- [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) — self-repair patterns per stage

## ADR Pointers

The `## ADR Pointers` content bucket — emitted as `#### ADR Pointers` H4 nested inside `### Detail` of the spoke output — links to ADR Issues (GitHub Issues with `adr` label) the spoke opened during Solutioning, OR justifies why no ADR was needed.

**Required elements:**

| Element | Form | Notes |
|---|---|---|
| ADR Issue references | Linked `#N` per ADR | Open or closed; ADR Issues use `adr` label per `pipeline/stage-05-solutioning.md` § 5 Phase A5 |
| Decision class per ADR | Per the ADR threshold in [`adr-authoring-guide.md`](../../../core/standards/adr-authoring-guide.md) § When to write an ADR | D-class items require explicit ADR; non-D-class do not |
| Skip rationale (if no ADR) | Inline narrative referencing ADR threshold criteria | Required when no ADR opened; justify against reversibility + confidence + cross-cutting impact criteria |

**ADR threshold (per [`adr-authoring-guide.md`](../../../core/standards/adr-authoring-guide.md) § When to write an ADR):** ADR required when decision is non-obvious AND any of:
- MODERATE / EXPENSIVE / IRREVERSIBLE reversibility
- LOW / MEDIUM confidence
- Cross-cutting governance impact (touches CLAUDE.md, OPERATIONS.md, `core/rules/`, or `release-process.md`)

Decisions below the threshold may be documented inline in `#### Design Decisions` without elevating to an ADR.

**Anti-patterns:**
- "No ADR needed" without skip rationale
- ADR opened for non-D-class decision (audit-trail bloat)
- ADR opened but not referenced from `#### ADR Pointers` (orphan ADR)

## § 3.5 The Solutioning Pre-Read (advisory, non-binding)

A Stage 5 spoke MAY post a **Solutioning pre-read** — a rich pre-implementation
analysis comment on the **parent issue** at Stage 5 entry, to orient the
implementing agent before Engineering picks the issue up. The pre-read is a
**distinct artifact** from the § 3 seven-section output frame and from the § 3
"Optional preamble": the output frame is the spoke's *deliverable* posted on the
sub-task; the pre-read is *advisory orientation* posted on the parent issue.

**The issue body remains the sole authoritative contract.** Per
[`ticket-information-architecture.md` § Source of Truth](../specs/ticket-information-architecture.md)
— "the issue body is the single authoritative record of what this issue IS", and
stage-review comments form an immutable audit trail that is NOT body content —
the pre-read NEVER modifies the issue's Acceptance Criteria, Proposed Change, or
Affected Files. Those remain the contract. The pre-read is structurally a
Stage-5 comment, so it already lives in the comment lane by that doc's rule; no
downstream stage reads it as scope.

**Required banner (the demarcation rule that makes the comment non-binding).**
A pre-read MUST open with the load-bearing banner line and MUST close with a
re-verify line:

```markdown
🧭 **Solutioning pre-read — ADVISORY, not scope**

Early design analysis to orient the implementing agent. It does **not** modify
this issue's Acceptance Criteria, Proposed Change, or Affected Files — those
remain the contract. Treat everything below as a starting point to **verify
against live state**, not a commitment. Line refs are as-of intake and must be
re-checked on the current `main`.

<... advisory analysis ...>

*Re-verify all paths and line numbers before acting; this pre-read is advisory
context, not the issue contract.*
```

- **Load-bearing tokens** (greppable demarcation): the literal banner string
  `Solutioning pre-read — ADVISORY, not scope`, an explicit one-sentence "does
  not modify AC / Proposed Change / Affected Files" statement, and the closing
  "advisory context, not the issue contract" re-verify line. The 🧭 emoji is
  OPTIONAL ornament — the string tokens carry the convention, so the convention
  stays greppable without the emoji.
- **Term disambiguation.** "ADVISORY" here means the pre-read is **non-binding
  relative to the issue-body contract** — distinct from the adversarial-design-review
  (RC-5) sense on the Stage-5 surface (see
  [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md)
  Phase A6.5, where adversarial findings are "advisory" meaning **non-gating
  relative to Collective Review**). Pre-read = non-binding vs. the body; RC-5 =
  non-gating vs. the operator's scope-lock.

**Worked example:** the operator-authored "Solutioning pre-read — ADVISORY, not
scope" comment on the originating intake issue is the canonical specimen of this convention.

**Mirror (intake-authority pair).** This convention governs Stage-5-*emitted*
advisory context (non-binding; the body stays the contract). Its mirror —
[`intake-style-guide.md`](../how-to/intake-style-guide.md) § 5c (The
Assumption-Handoff Convention) — intake-*emitted* `[ASSUMPTION –
CONFIRM]` assumptions, directional and owned downstream via `owner:` /
`to close:` — governs the intake side. Same intake-authority theme, different
emitting stage, so the two homes diverge by stage and compose by
cross-reference. Together they complete the intake-authority
WHAT-vs-HOW-vs-advisory boundary under the intake-authority epic.

**Omission is the correct non-ceremony signal.** The pre-read is optional — a
spoke with no rich pre-implementation analysis to convey simply does not post
one. Omission carries no penalty.

## § 4. Composition Seams

The Stage 5 output comment composes with three other standards. Each composition seam is one specific H3 section in the comment frame; the composition rule is documented here.

### § 4.1 R1 Evidence-Grounding

When the Stage 5 spec **canonicalizes a convention** (per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) § What counts as "canonicalizing a convention"), the spoke produces a 2-part artifact at `### Evidence-Grounding (R1)` (H3 #4 in the comment frame), placed AFTER `### Detail` and BEFORE `### Tier-A Activated Design Artifacts`.

**Placement rule:** The `### Evidence-Grounding` H3 contains one `#### Canonicalization: <name>` H4 per canonicalization in scope (often 1-3 canonicalizations). Each H4 carries the Current-state enumeration table + Survey command + Canonical choice + Canonical-choice justification + Out-of-scope drift block per the standard's Schema.

**Omission rule:** When NO canonicalization fires, the H3 section is OMITTED entirely (do not include with placeholder text). The omission is a positive signal — the spec did not canonicalize.

**Composition with `### Decisions & Recommendations`:** Each canonicalization in the Evidence-Grounding section may reference a numbered R-recommendation in the Decisions section if the canonicalization shapes a downstream action.

### § 4.2 Tier-A Design-Artifact Declaration

When the Stage 5 spec **activates Tier-A** (per [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 7 — new explanation/ doc, materially modified explanation/ structural diagram, new schema/contract/output-format file, new architectural concept), the spoke declares the activation at `### Tier-A Activated Design Artifacts` (H3 #5 in the comment frame), placed AFTER `### Evidence-Grounding` and BEFORE `### Decisions & Recommendations`.

**Placement rule:** Table with columns artifact path / flow class / trigger / activation tier (A NEW or B refresh) / G-CL6 obligation.

**Omission rule:** When NO Tier-A activation fires, the H3 section is OMITTED entirely. Same positive-signal convention as Evidence-Grounding.

**Composition with Stage 13 G-CL6:** The declared artifacts are read at Stage 13 Close by the spoke implementing G-CL6 refresh-gate (per `gate-criteria-spec.md` Gate 13 row G-CL6). The declaration in this section is the load-bearing input to G-CL6.

### § 4.3 Stage 5→6 Boundary Contract (per stage-io-contracts.md)

The `### Output for Stage 6` H3 (#7 in the comment frame) is the boundary handoff to Stage 6 Engineering. Format conforms to [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) `boundary-stage-5--stage-6` contract.

**Required elements:**

| Element | Form | Notes |
|---|---|---|
| Per-change H4 | `#### Change N — NEW / MODIFY / DELETE` | One H4 per file change |
| File path | `**Path:** <absolute-from-repo-root>` | Resolves against `pmo-platform/` if relative |
| Intent | `**Intent:** <one-sentence>` | Editor-actionable verb |
| Mechanism | `**Mechanism:** <Stage 6 spoke action>` | Cite Write / Edit / Bash tool affordance |
| Literal scaffold | Fenced markdown code block | Required for NEW files; optional for MODIFY (provide context + before/after fragment) |

**Composition with Stage 5 § 6 Date-variable discipline:** If the spec creates ≥1 downstream load-bearing identifier carrying a date in `YYYY-MM-DD` form (audit-folder paths, AC verifier identifiers), the `### Output for Stage 6` H3 MUST include a `### Date Variable` sibling block per [`date-variable-convention.md`](../../../core/standards/date-variable-convention.md). Variable `${AUDIT_DATE_UTC}` resolves at Stage 6 first commit.

**Composition with Stage 5 Phase A4.2 Integration-AC Emission:** If the issue under design has ≥1 upstream dependency (a native `blocked-by` edge OR a directional soft edge naming this issue as downstream in the Stage-4 § Dependency Graph), the `### Output for Stage 6` H3 MUST include an optional `### Integration Acceptance Criteria` sub-heading listing the `INT-N` integration ACs authored at Phase A4.2 (per [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) § Phase A4.2). Each `INT-N` names the upstream issue, the shared surface, and a mutual-consistency assertion gradable at Stage 8 under the standard per-criterion verdict enum. The sub-heading is **present-when-triggered** and **OMITTED (non-ceremony) when the issue has no upstream dependency** — the same conditional-omission discipline as the Cascade-Sweep and ref-form blocks above.

## § 5. Template Scaffold (copy-paste ready)

Stage 5 spokes use the scaffold below as starting draft. Replace bracketed placeholders; remove conditional sections (Evidence-Grounding / Tier-A) when their omission rules fire.

```markdown
## Stage 5 Solutioning — v<X.Y>-<milestone-slug> (issue #<N>)

**Persona:** Principal Engineer — Architecture Assessment ([release-personas.md §Stage 5](../specs/release-personas.md))
**Stage 4 anchor:** [#<2533-equivalent>](https://github.com/{REPO}/issues/<2533-equivalent>)
**Stage 5 spec anchor:** [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md)
**Sister issue(s):** [optional — sister Stage 5 sub-tasks in same release with coordination notes]

---

### Summary (30 seconds)

<2-4 sentence verdict — main decision, recommended path, blocker if any>

---

### Detail

#### Design Decisions

<D-decision table per § Design Decisions of solutioning-output-template.md>

#### Blast Radius

<file change matrix + schema impact + consumer enumeration + cross-PR contention per § Blast Radius>

#### Feasibility Assessment

<Mode 3/4 flags + cross-release coordination + testability + rollback per § Feasibility Assessment>

#### ADR Pointers

<ADR Issue refs OR skip rationale per § ADR Pointers>

---

### Evidence

<reproducible commands + source citations — file:line / gh issue view / git log / grep>

---

### Evidence-Grounding (R1)

<2-part artifact per evidence-grounding-standard.md when canonicalizing; OMIT this entire H3 when no canonicalization fires>

#### Canonicalization #N: <convention name>

**Current-state enumeration:**
| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| ... | ... | ... | ... |

**Survey command:** `<reproducible grep/gh invocation>`
**Survey date:** `YYYY-MM-DD` at commit `<short SHA>`
**Canonical choice:** `<value>`
**Canonical-choice justification:**
- Audit finding: `<reference>` OR
- Upstream convention: `<upstream-reference-catalog.md entry>` OR
- Documented rationale: `<ADR # or governance doc section>`

**Out-of-scope drift detected:**
| File / location | Observation | Routing |
|---|---|---|
| ... | ... | Tier 1 [ADJUST] / next-release issue / accepted-residual |

---

### Tier-A Activated Design Artifacts

<declaration per design-artifact-standard.md § 7 when applicable; OMIT this entire H3 when no Tier-A activation>

| Artifact path | Flow class | Trigger | Activation tier | G-CL6 obligation |
|---|---|---|---|---|
| ... | ... | ... | A NEW / B refresh | ... |

---

### Decisions & Recommendations

| Recommendation | Status |
|---|---|
| **R1** — <action> | RECOMMENDED / OPTIONAL / DEFERRED |
| ... | ... |

**Empirical Verification (R3):**

| Recommendation | Verification command / artifact read | Observed result | Risk if accepted |
|---|---|---|---|
| R1 | `<command>` | `<result>` | LOW / MEDIUM / HIGH |
| ... | ... | ... | ... |

---

### Output for Stage 6

#### Change 1 — NEW / MODIFY / DELETE

**Path:** `<absolute-from-repo-root>`
**Intent:** <one-sentence>
**Mechanism:** Stage 6 spoke uses <Write / Edit / Bash> with the literal content below.

\`\`\`markdown
<literal file content or diff fragment>
\`\`\`

#### Change 2 — ...

### Integration Acceptance Criteria
<!-- OPTIONAL — present ONLY when this issue has ≥1 upstream dependency (Phase A4.2); OMIT entirely otherwise -->

- [ ] **INT-1 (vs #<upstream-N>):** On <shared surface — file/table/schema/enum/capability>, this issue's output remains mutually consistent with #<N>'s output — <the concrete consistency assertion, gradable yes/no by the Stage-8 judge>. *Grades at Stage 8 Phase B under the standard per-criterion verdict enum.*
```

## § 6. Failure Modes

Domain-specific anti-patterns observed during Stage 5 spoke authoring. Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), each entry uses the 5-field template (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries a category tag.

### F-1. Empty Detail / over-structured admin (PROC)

| Field | Value |
|---|---|
| **Signature** | Detail H3 contains only headers ("#### Design Decisions" / "#### Blast Radius" / etc.) with empty or near-empty content; admin sections (Summary / Evidence) carry most substance |
| **Conditional** | Fires when spoke treats the 4 content buckets as structural-only checkbox rather than substantive content |
| **Root cause** | Misreading the template — buckets are content categories, not checklist items |
| **Mitigation** | Each H4 bucket must carry substantive content (tables, narrative, citations); ≥1 row in any required table; empty buckets indicate scope underspecified or D-decision-only release |
| **Principal-vs-junior response** | Junior: fills empty buckets with restating the section name. Principal: collapses empty buckets to a single inline sentence in Detail explaining why the bucket is empty for THIS issue (e.g., "Blast Radius: bounded to a single 5-line cross-ref; no schema impact, no consumer cascade — see Change 2 below") |

### F-2. Evidence-Grounding mis-applied or omitted (TRIG / OUT)

| Field | Value |
|---|---|
| **Signature** | Spec canonicalizes a convention but no `### Evidence-Grounding (R1)` H3 present, OR the H3 is present but contains generic-rationale citations without survey command |
| **Conditional** | Fires when spec triggers Evidence-Grounding (per [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) trigger table) and the artifact is missing or insufficient |
| **Root cause** | Spoke didn't recognize canonicalization triggered (TRIG) OR included Evidence-Grounding section without empirical survey (OUT) |
| **Mitigation** | Before posting comment, spoke runs the test of last resort: "could a downstream reader ask what is the current state of this convention?" — if YES, Evidence-Grounding required. Survey command MUST be reproducible (file paths + grep pattern + SHA pinning). |
| **Principal-vs-junior response** | Junior: cites "platform convention" without survey. Principal: runs the survey command before claiming the canonical choice; documents out-of-scope drift even when zero entries (omission of the drift block is a structural defect per `evidence-grounding-standard.md` load-bearing test) |

### F-3. Tier-A declaration omitted when activation fires (TRIG)

| Field | Value |
|---|---|
| **Signature** | Spec creates new schema/contract/explanation file OR materially modifies existing Tier-A artifact, but `### Tier-A Activated Design Artifacts` H3 omitted |
| **Conditional** | Fires when [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) § 7 activation criteria are met and declaration is missing |
| **Root cause** | Spoke didn't check activation matrix; or treated Tier-A as a "concept" not a "spec" surface |
| **Mitigation** | Phase A1 design-scope assessment per `pipeline/stage-05-solutioning.md` § 5 Phase A includes Tier-A activation check. Spoke runs the check explicitly; declares positive OR negative result (omission means "no activation" — but the spoke should have CHECKED) |
| **Principal-vs-junior response** | Junior: declares Tier-A only when prompted. Principal: applies the activation matrix as Phase A1 standing procedure; the OMIT rule means "no activation fired" — but the spoke must have run the check |

### F-4. ADR Pointers — opening ADR for non-D-class decisions (PROC)

| Field | Value |
|---|---|
| **Signature** | `#### ADR Pointers` section lists ADR Issues for decisions that don't meet the ADR threshold per [`adr-authoring-guide.md`](../../../core/standards/adr-authoring-guide.md) § When to write an ADR |
| **Conditional** | Fires when CHEAP-reversibility + HIGH-confidence + no-cross-cutting decisions are elevated to ADR audit-trail |
| **Root cause** | Conflating "documented decision" with "ADR-grade decision" |
| **Mitigation** | Apply the ADR threshold: ADR required when decision is non-obvious AND (MODERATE+ reversibility OR LOW/MED confidence OR cross-cutting governance impact). Below threshold = document inline in `#### Design Decisions`, no ADR. |
| **Principal-vs-junior response** | Junior: opens ADR for every D-decision (audit-trail bloat). Principal: applies the threshold; inline-documents the majority; reserves ADR for genuine D-class items |

### F-5. Output for Stage 6 — vague mechanism (HAND)

| Field | Value |
|---|---|
| **Signature** | `### Output for Stage 6` H3 lacks per-change Mechanism field; Stage 6 spoke must re-derive Edit/Write/Bash invocations from prose |
| **Conditional** | Fires when spec is prose-heavy and the file-change spec is implicit rather than Edit-ready |
| **Root cause** | Spoke treats Stage 6 as a smart agent that can interpret intent; ignores the boundary-contract requirement |
| **Mitigation** | Each file change H4 carries Path / Intent / Mechanism fields explicitly. NEW files include literal scaffold in fenced code block. MODIFY files include before/after fragment or section-anchor location. |
| **Principal-vs-junior response** | Junior: "create file XYZ with the structure described above" (Stage 6 must interpret). Principal: provides literal scaffold + Edit-ready spec; Stage 6 spoke uses Write tool directly with the scaffold as content |

## § 7. Cutover + Version History

### Cutover

**Applies to all releases entering Stage 5 going forward.**

The template codifies the empirical pattern that emerged organically across prior Stage 5 outputs — pre-cutover compliance is a positive observation, not an enforced requirement.

### Version History

| Version | Date | Change | Issue |
|---|---|---|---|
| Initial | 2026-05-24 | Initial authoring — milestone Key AC #1 deliverable; codifies the 7-section comment frame, 4 required content buckets, composition seams with R1 + Tier-A + Stage 5→6 contract, and the literal copy-paste scaffold | — |
| — | 2026-06-19 | Add § 3.5 The Solutioning Pre-Read — advisory/non-binding convention (banner demarcation rule, sole-contract composition with the ticket-information-architecture source-of-truth rule, RC-5 term disambiguation, worked-example specimen, intake-style-guide § 5c mirror) | v2.05 |

Future revisions append rows here. Per workspace precedent (git is canonical retention), this table is a navigation aid, not a parallel snapshot.

## Related References

- [`evidence-grounding-standard.md`](../../../core/standards/evidence-grounding-standard.md) — R1 Evidence-Grounding subsection schema; composition seam at H3 #4 of the comment frame.
- [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) — Tier-A activation matrix; composition seam at H3 #5 of the comment frame.
- [`planning-solutioning-handoff.md`](../../../core/standards/planning-solutioning-handoff.md) — Sister K1 standard (Stage 4→5 ENTRY contract; this template owns Stage 5→6 OUTPUT contract). Authored in same release as the entry-contract sister standard.
- [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) — Stage 5 pipeline shard (consumer at § 6 Outputs cross-ref).
- [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) — Stage 5→6 boundary contract; consumed by `### Output for Stage 6` H3 format.
- [`hub-spoke-bridge.md`](../how-to/hub-spoke-bridge.md) Procedure 3 Spoke Template — Chip-prompt injection point at Stage 5 entry.
- [`adr-authoring-guide.md`](../../../core/standards/adr-authoring-guide.md) § When to write an ADR — ADR threshold (the when-to-write rubric) referenced by the `#### ADR Pointers` content bucket spec.
- [`decision-discipline.md`](../../../core/disciplines/decision-discipline.md) — M1/M2/M3 mechanisms referenced by `#### Design Decisions` content bucket spec.
- [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) — 5-field anti-pattern template applied in § 6 Failure Modes.
- [`upstream-reference-catalog.md`](../../../core/standards/upstream-reference-catalog.md) — Upstream-compatibility citation source for Cross-D scan.
- [`release-notes-standard.md`](release-notes-standard.md) — Sibling K1 standards doc; Part 1 copy-paste scaffold pattern precedent.
- [`canonical-skill-structure.md`](../../../core/standards/canonical-skill-structure.md) — Sibling K1 standards doc; H2 section-numbering convention precedent.

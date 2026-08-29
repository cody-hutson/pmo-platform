<!-- reference-durability: allow-link -->
---
title: "ADR-162 — An obligation-shaped declaration joins class 3 by a second admission form, not a fourth gate class"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-29
release: declarations-have-a-firing-surface
deciders: "Stage 5 Solutioning spoke (design, candidate elimination, evidence-grounding) + hub Procedure 4 adversarial evaluation (independent re-probe; two of its own Stage-4 claims falsified) + operator at Collective Review scope-lock (D-3 / D-4 / D-5) + Stage 6 Engineering spoke (build, mechanism re-derivation)"
tags: [gate-efficacy, governance-as-code, admission-test, prose-declared-predicate, enforcement-surface, hooks, ADR-031, ADR-053, ADR-109, ADR-112]
source_observations:
  - "Three governed rules were each not applied in a single session, same signature every time — the rule existed, declared its trigger, had no surface that acted at the trigger, was not applied, and produced no signal that it had been skipped. A composition doctrine's seven-step method never ran; roughly twenty work items bypassed the ambient auto-log path; a scope prohibition was violated seventeen days after its own decision record was accepted and went undetected for nineteen more."
  - "Falsification applied to the obvious cause and it failed. The counterfactual 'the doctrine was not loaded' does not hold: a compressed form of the rule was held in memory, its dependency half was skipped anyway, and the size overage was computed, stated aloud, and not acted on. Knowledge was present and unused, so 'not loaded' is a waypoint, not the root."
  - "The platform already owned a firing-surface machine. `core/standards/gate-efficacy-standard.md` class 3 carries a `**Runner:**` declaration, a gate-coverage register row, a `runner-def: <path>::<anchor>` pointer, and `deploy.sh --check` Check 62, which recomputes every pointer on every run so that 'the named runner still carries the predicate' is a standing computation rather than an authoring claim."
  - "That machine's admission test structurally excluded the observed class, and the standard said so in terms: 'A normative rule that constrains conduct without stating a verdict declares no check and is out of scope.' All three evidence rows constrain conduct and state no verdict. The gap was never 'no declaration machinery exists' — it was that the machinery covered verdict-shaped predicates and not obligation-shaped procedures."
  - "Check 62 required no code change to admit the new form. Its predicate body extracts `runner-def:` pointers from the register and recomputes each one, indifferent to which limb admitted the row. Measured at the release baseline: four pointers, all resolving; five after this card's own slice; and seven at merge, still all resolving — the sibling slice adds the sixth when its detector ships, and the composition-doctrine row carries a second so both of the doctrine steps it names are anchored rather than one. Every one of those additions is a register-row edit and none is a code change. The narrow thing was the admission test; the computation was already general."
  - "The corpus sweep the originating card feared does not exist. Class 3's obligation already attaches 'on the change, not on the corpus: no scan and no allowlist', and its register is 'never required to be exhaustive in one pass'. Inheriting that posture means zero retroactive edits and no trigger-declaration field on any document, which is also what drops the card's reversibility from MODERATE to CHEAP."
  - "A probe over the whole corpus found no existing machine-readable trigger-declaration field: 808 frontmatter blocks, one incidental `enforcement:` key, against a sensitivity arm returning 523 for `type:` and a specificity arm returning zero. A net-new declaration registry would therefore have been genuinely net-new — and a second registry of what the platform declares and what enforces it."
  - "Applying the mechanism to its own first instance immediately surfaced a live failure. The only resolvable runner for the composition doctrine carried Steps 1 and 5 and not Steps 3 or 4 — precisely the half the motivating defect skipped — while the check reported that row resolvable, because resolution asserts anchor presence and not predicate completeness."
---

# ADR-162 — An obligation-shaped declaration joins class 3 by a second admission form, not a fourth gate class

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

## Context

The platform states a great many governed procedures in prose. A procedure names a moment — *when a milestone is proposed*, *whenever you identify a gap*, *on any write to this surface* — and an act the agent must perform at that moment. Whether the act happens has, until now, depended on whether the agent happened to recall the rule.

Three such procedures were each skipped in a single session. None produced any signal that it had been skipped, and two of the three failures compounded: the values that sized an oversized bundle were the same values a scope prohibition forbade caching. The originating analysis named the systemic pattern *the rule existed but was not enforced*, with three member findings, and stated one hard constraint on the remedy: **the intervention cannot itself be a prose rule**, because the observed failure class *is* prose rules not firing.

The platform already owned the machine this needs. `gate-efficacy-standard.md` defines a third gate class — a **prose-declared normative predicate** — with a named runner, a gate-coverage register row, a machine-checkable `runner-def:` pointer, and a deploy check that recomputes every pointer on every run. What it did not have was an admission test that could see these three procedures. Class 3 admitted a passage by `L1 ∧ L2`, where `L1` is a **verdict** limb, and the standard excluded conduct-constraining rules explicitly. All three evidence rows constrain conduct and state no verdict.

So the question was never *what mechanism should we build*. It was **why does the existing mechanism not reach this class, and what is the smallest honest change that makes it**.

## Decision

**Class 3 gains a second admission FORM — `L1′ ∧ L2`, the obligation limb — and does NOT become a fourth gate class.**

`L1′` holds when a passage declares a **procedure with a stated trigger**: a named condition plus an act the agent MUST perform when that condition holds, and no verdict stated for the negation. `L1 ∧ L2` is preserved byte-for-byte as **class 3-V**; `L1′ ∧ L2` is **class 3-O**. Where a passage carries both a trigger and a verdict, **L1 governs and L1′ adds nothing** — a passage is admitted once, by one form.

**The admission bar is the stated trigger, and nothing looser.** A rule with no named condition — *"be thorough"*, *"prefer durable structures"* — is not admissible, because there is no observable moment at which a runner could be said to have fired. This reuses the platform's own index-eligibility bar rather than introducing a second admission philosophy, and it closes the originating card's open scope question: the mechanism covers governed procedures **with a declared trigger**, not all governed procedures.

**A class-3-O passage owes exactly what a class-3-V passage owes** — a `**Runner:**` label in the passage, a row in the gate-coverage register, and a `runner-def:` pointer where a runner is named — with **one divergence**, in the second disposition available when no resolvable runner can be named:

| | class 3-V | class 3-O |
|---|---|---|
| Disposition 1 | **Wire it** | **Wire it** — identical |
| Disposition 2 | **Downgrade it** — restate as non-normative, dropping the verdict language | **Register it as a named gap** — keep the obligation, record the row with an empty enforcing-gate cell, and declare the observable that would close it |

A class-3-O row whose runner is a named review step, or which is a named gap, additionally MUST state **the observable the compliant path emits and the bypassing path does not**.

## Why a form and not a class — the cascade argument, stated because it is the whole shape

A fourth class is the obvious rendering and it is the wrong one, on a cost that is structural rather than aesthetic.

The standard's scope-boundary heading reads *"three gate classes, this standard governs two."* That count is repeated in the section body, in the version-history narrative, and in every consumer that cites the taxonomy. Adding a fourth class cascades across all of them, and the platform's own count-cascade discipline exists because that class of edit is reliably done partially — a heading updated, a version-history row left stale, a consumer never opened.

An alternative first limb inside an existing class cascades **nowhere**. 3-V and 3-O share one owner document, one register, one `runner-def:` form, and one computation. The count stays three by construction, and no consumer of the taxonomy sees any change at all.

The taxonomy also earns its retention on its own cut rather than on inertia. It separates gates by **who renders the verdict** — an evaluator for stage-transition gates, a script for automated-assertion gates, the agent for prose declarations. An obligation-shaped procedure's verdict-renderer is the agent, which is class 3's renderer. It belongs *inside* class 3, not beside it.

**The falsifiable evidence that the structure fits: Check 62 required no code change.** Its predicate extracts `runner-def:` pointers from the register and recomputes each, indifferent to which limb produced the row. A design that needed the computation rewritten would have been evidence the class was the wrong home; a design that needed nothing rewritten is evidence it was the right one.

## Why the second disposition diverges

A verdict-shaped predicate that cannot be run is **lying**. It claims a FAIL that nothing can render, so deleting the claim is a correction and the artifact becomes more truthful.

An obligation-shaped procedure that cannot be mechanically observed is **not lying**. It still correctly states what the agent must do; what it lacks is a detector. Downgrading it would delete a correct instruction — a regression dressed as hygiene. Registering it as a named gap keeps the instruction and makes the absence of enforcement countable, which is the coverage-matrix discipline the register already applies elsewhere: an empty enforcing-gate cell is a named gap, visible and trackable, not a silent omission.

The named-gap disposition is deliberately not a loophole. A named-gap row carries **no** `runner-def:` pointer, because a pointer at a runner that does not carry the predicate is a false resolution; and stripping every pointer from the register to silence the check reports `NOSET` on every mode, so there is no silent-pass path out.

## Why a tool-call-time hook is not the mechanism — the falsification

A `PreToolUse` hook is the first idea the evidence suggests, and it was eliminated on a **falsified premise**, not on cost. The premise it rests on is that a governed act is visible at the tool-call boundary. It is not, and the reason is stronger than the framing the originating card carried.

The card recorded that the ambient auto-log path's work-item creation is *"not payload-detectable — the hook never sees it."* The second clause is **false as literally written**: a shipped hook gates on the same tool and inspects that very command string, so the string *is* visible. Correcting it makes the real obstacle sharper rather than softer.

**The non-detectability is semantic, not lexical.** The sanctioned auto-log path's work-item creation and a bypassing agent's work-item creation are **byte-identical tool calls**. No payload field carries which skill or mode is executing, and hooks read no session, parent-session, or subagent field — an empirical survey of the whole hook suite found zero hooks reading any such field, and every blocking hook triggering on the tool-call payload alone. **The compliant call and the violating call are indistinguishable at the payload layer.** Compliance is not a property of the payload, so no hook design reaches it.

**Two of the three evidence rows have no distinguishing tool-call signature at all.** Composing an oversized, dependency-blind milestone leaves an edit to a milestone description that is byte-identical to any other milestone edit. The third — a prohibited value cached in a surface outside the repository — is not written through a governed tool call at the moment that matters.

This is the third time the platform has reached this wall from an adjacent problem, and the prior two dispositions are cited rather than re-derived: a hook keyed to a per-action tier classification was rejected because the eligibility test needs a classification the payload lacks, and a hook for a claim-shaped trigger was deferred because a hook observes a tool call while that trigger fires on a claim. Recording the falsification here is what stops the question being re-opened a fourth time.

## The boundary with at-close obligation measurement

A sibling initiative in a different milestone, under the same parent epic, measures **newly-declared obligations at release close** — for a control a release declares, what fraction of the population it ranges over conforms, and who owns the gap. The overlap with this decision is real and partial, and it is a **composition seam, not a duplication**.

| | this decision | the at-close measurement initiative |
|---|---|---|
| Evaluand | a governed **procedure** that declares a **trigger** | an **obligation / control** newly **declared by a release** |
| Question | when the trigger fired, did the procedure run — and if not, is there a record? | at close, over the population the obligation ranges over, what fraction conforms? |
| Temporal anchor | **at-trigger**, continuous, every occurrence | **at-close**, once per release |
| Failure cured | a rule held-but-not-applied (**conduct**) | a control declared-but-unpopulated (**state**) |

**This decision owns the DECLARATION and the AT-TRIGGER fire-or-record surface. The sibling owns the AT-CLOSE MEASUREMENT.** Where they touch, it is a consumer relationship: a class-3-O register row **is** one instance of a declared obligation, so the at-close work should *enumerate* class-3-O rows as a population source rather than re-invent the declaration.

**The falsifying test for "same machine":** a close-time population count structurally cannot observe a runtime skip. It measures corpus state at a release boundary; this decision concerns agent conduct at the moment of an act. Neither can deliver the other's result. Two machines.

## The first instance's predicate is declaration-scoped, and that is a deliberate trade

The first instance registered under this form is a drift class detecting surfaces that hold a resolved target-side referent. Its detector's population is **declaration-scoped**: it examines surfaces that *declare* the obligation, not every surface that might cache a target fact.

That is a deliberate trade and it is stated rather than glossed. A content scan over arbitrary surfaces cannot distinguish a cached target fact from a legitimate mention of one, so it would generate false positives — and for a detector whose whole value is trust, false positives are worse than no detector. The cost is that an **undeclared** cache is invisible. That residual is exactly the class this decision's own mechanism addresses, from the other side: it is closable by requiring the declaration, not by scanning harder.

## Consequences

**Governed obligations become detectable, not enforced — and the release says so.** The runner of the mechanism is advisory and deploy-time-only, and its first instance is warn-mode and skips entirely where the surface it reads does not exist. That is coherent and deliberate rather than an oversight: the standard's own definition of a detectable signal is *a named, resolvable runner whose verdict is observable and whose resolution is recomputed*, chosen precisely so an honest deploy-time detector stays conformant rather than being defined out of the class it instantiates. Defining "detectable" as *gate-enforced or CI-reachable* would have made this release's own first instance non-conformant with the rule it ships.

**The mechanism's limits are enumerated in the standard, not implied.** Seven of them: it does not detect a runtime skip; it does not reach any surface outside the repository; no hook can separate compliance from bypass on a byte-identical call; resolution asserts anchor presence rather than predicate completeness; the class is advisory and deploy-time-only; it does not detect an obligation that was never registered, because the check resolves the rows the register contains and nothing scans the corpus for a predicate carrying no row; and the declared observable a row must state is reviewer-verified rather than machine-checked. A mechanism that leaves its own limits unstated reproduces the failure class it exists to close.

**Anchor choice becomes a substantive authoring act.** Because resolution asserts anchor presence, the anchor must name the part of the predicate whose loss would matter. This is not hypothetical: the first wired row's own runner carried half its predicate and would have resolved clean, which is why that half was completed in the same change rather than registered around.

**No corpus sweep, and therefore cheap rollback.** The on-change posture is inherited, so no document gains a trigger-declaration field and no existing passage is rewritten except the two that are themselves the evidence. A revert restores the prior state exactly and returns the check's pointer count to its previous value.

**A future author can still get this wrong in the one way that matters.** Adding a fourth class later inherits the whole cascade this decision avoided. The count is held at three by construction, and this record is the reason it should stay there.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| **A `PreToolUse` hook keyed to the tool calls that mark a governed task class** | **Falsified premise, not cost.** Compliance is not a property of the tool-call payload: the sanctioned call and the bypassing call are byte-identical, hooks read no session/skill/mode field, and two of the three evidence rows have no distinguishing signature at all. It also re-opens two prior dispositions that hit the same wall. |
| **A net-new `trigger:` frontmatter field on governed procedures plus a net-new deploy check** | **Extend-before-create, plus blast radius.** Two covering surfaces already exist; a third would be a parallel registry of *what the platform declares and what enforces it* — a shadow single-source. It also manufactures the corpus-wide sweep the on-change posture avoids, at worse reversibility, for the same outcome. |
| **A fourth gate class** | The cascade argument above: a fourth class propagates across the scope heading, the version history, and every consumer repeating the count, and buys nothing the alternative first limb does not. |
| **A corpus-wide honesty pass labelling every unrunnable obligation advisory** | Not a rival — it is *already* class 3's exit disposition, and it is adopted here as class 3-O's disposition 2. As the *sole* answer it states the truth and adds no surface. |
| **Extending the decision-time-adherence index with an action-shaped checkpoint row** | As the mechanism it is prose whose enforcement is the agent honoring the index plus a reviewer inspecting the emitted token — nothing blocks an un-tokened claim mechanically. That reproduces the failure class the originating card forbids. Its one load-bearing part, the emitted-observable pattern, is reused here rather than a second trailer family being invented. Widening that index's own trigger would also re-open a settled bounded-index decision. |
| **Defining "detectable signal" as gate-enforced or CI-reachable** | It would define this release's own first instance out of conformance with the rule the release ships, which is internally incoherent. The honest weakness is named in the non-coverage enumeration instead of hidden by a definition. |

## Reversibility

**CHEAP.** The change is an additive admission limb, one disposition table, one non-coverage enumeration, three register rows, two passage labels, one checklist trigger extension, and one sub-check pair. No code changed. A revert restores the prior state exactly and returns Check 62's pointer count to its previous value.

The originating card recorded **MODERATE**, justified by *"every governed procedure edited to carry a trigger declaration is a corpus-wide change that is tedious to walk back."* That premise does not hold under the on-change posture, because there is no such sweep.

## Related ADRs

- [ADR-031](ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md) — the empirical survey establishing that no hook in the suite reads any session, subagent, or transcript field. This decision cites that survey rather than re-running it.
- [ADR-053](ADR-053-pre-gate-eligibility-forcing-function.md) — rejected a `PreToolUse` hook for an adjacent problem on the same infeasibility: the eligibility test needs a per-action classification the payload lacks.
- [ADR-109](ADR-109-external-target-knowledge-scope.md) — the scope decision whose deliberately-deferred detector is the first instance registered under this form. Not edited; its forward reference resolves.
- [ADR-112](ADR-112-decision-time-adherence-trigger-layer.md) — deferred a hook for a claim-shaped trigger, and rejected a further charter bullet for this exact failure class. Its bounded index is retained unchanged here; only its emitted-observable pattern is reused.
- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — the compose-not-absorb rule under which the readiness group widens what it composes rather than growing check logic of its own.

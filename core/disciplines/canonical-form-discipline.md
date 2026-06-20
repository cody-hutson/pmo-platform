---
title: Canonical-Form-Application Discipline
purpose: Meta-discipline governing how the platform's discipline frames are applied — the distinction between applying a discipline's substance and producing its canonical artifact form, the produce-canonical-artifact-OR-document-partial-conformance protocol, and a registry of the canonical-form frames that references per-frame template owners rather than inlining their bodies
applies_to: decision-discipline.md § 2.1.2 (the decision-side conformance hook), the per-stage pipeline shards that produce a canonical-form-framed artifact (Stage 5 Solutioning, Stage 13 Close), and any frame-template card that registers itself against a registry frame row
parallel_to:
  - ../disciplines/decision-discipline.md
  - ../disciplines/review-discipline-principles.md
source: v11.01 stage-design-quality audit finding F-Release-3 (the canonical-form-application gap — canon substance applied while the canonical artifact form is partial-or-absent, observed at the same load-bearing degradation class across multiple phases and frames); design inherited from the KA-Discipline epic
type: discipline
reversibility: CHEAP
---
<!-- repo-integrity: allow-issue-ref -->

# Canonical-Form-Application Discipline

A meta-discipline. It does not add a new gate and it is not a template library. It governs one thing: when a platform discipline frame applies to a piece of work, how that frame's *form* is honored — by producing the frame's canonical artifact, or by deliberately documenting a partial-form conformance with explicit rationale. It names the degradation class this guards against, states the application protocol, and carries a registry of the frames that *references* their per-frame template owners without inlining their bodies.

**Relationship to `decision-discipline.md` and `review-discipline-principles.md`:** Parallel, not extension. This discipline owns the *artifact-shape* question (does the produced artifact take its frame's canonical form?). Decision discipline owns the *decision-producer* question (localization, opposing view, pattern check). Review discipline owns the *review-finding* question (severity, root cause, residual risk). A decision that produces a frame-governed artifact consults this discipline for the form question via `decision-discipline.md` § 2.1.2; a review that finds a missing canonical form reports it as a review finding. Different questions, different consumers — cross-reference, no inheritance.

---

## 1. Purpose and Scope

This discipline governs **canonical-form application** across the platform's discipline frames. A *frame* is a domain whose practice has a recognized canonical artifact: architecture decisions have the ADR, retrospectives have the retro/lessons register, and so on. When work falls inside a frame, two distinct things can be true or false independently, and this discipline exists to keep them from being conflated.

**What this governs:**

- The distinction between *applying a discipline's substance* and *producing its canonical artifact form* (§ 2).
- The protocol for honoring a frame's form when the frame applies — produce the canonical artifact, OR document a partial-form conformance with explicit rationale (§ 3).
- The registry of canonical-form frames and their template owners (§ 4) — a pointer surface, not a template library.
- The wiring of the form question into the decision-side localization check and the per-stage pipeline outputs (§ 5).

**What this is NOT:**

- It is **not a new gate.** It adds no stage-transition criterion and blocks nothing on its own. It is consulted by the consumers named in § 5; it is not itself an enforcement surface.
- It is **not a template library.** It carries no frame's template body. Each frame's canonical-form template is owned elsewhere (§ 4 names the owners). This file references those owners; it never duplicates them — duplicating them is exactly the template-proliferation failure this single-doc-references-templates boundary prevents.
- It is **not a re-design of any frame.** The frames, their canonical forms, and the decision that the cluster is seven frames (not eight) are inherited design, consumed here, not restated.

---

## 2. The Load-Bearing Distinction

The load-bearing concept of this discipline is that **canon substance applied** and **canonical-form conformance** are independent properties. A piece of work can have one without the other. Treating them as one property is the conflation that produced the originating audit finding.

### 2.1 Canon substance applied

*Canon substance applied* means the discipline's method or practice was actually followed. The architecture decision was genuinely deliberated against alternatives and trade-offs; the retrospective genuinely surfaced what surprised the team and what to change. The substance is the reasoning, the practice, the judgment the frame calls for — done.

Substance can be present in any container: a chat thread, a comment, a paragraph in an unrelated document, an undocumented but real decision. Substance-present says nothing about the artifact's shape.

### 2.2 Canonical-form conformance

*Canonical-form conformance* means the artifact that records the work takes its discipline's **canonical shape** — the recognized, durable, addressable form that the frame's template defines. An ADR in the immutable-markdown-ADR form is canonical-form-conformant; the same decision captured only as three sentences in a PR comment is not, even when the *substance* (the decision itself) is identical.

Form conformance is what makes the work **findable, citable, durable, and reusable** at the frame's expected addressability. It is the property that the frame's template exists to produce.

### 2.3 The degradation class

The degradation class this discipline guards against is **substance-present / form-partial-or-absent**: the canon substance is applied, but the canonical artifact form is partial or missing. This is the load-bearing failure — not "the work was not done" (substance absent is a different, more visible problem), but "the work was done and then not given its canonical form," so it silently fails to be findable or reusable at the frame's expected addressability.

This is the originating finding **F-Release-3** from the v11.01 stage-design-quality audit: the platform exhibited this exact degradation across multiple phases and multiple frames at the same load-bearing class — decisions made but not rendered as ADRs, retrospectives held but not rendered as registers, and so on. The degradation is insidious precisely because the substance *is* there: a reviewer checking "was the decision made?" sees yes and moves on, missing that the canonical form — the thing that makes the decision survive and be cited later — was never produced. This discipline makes the form question a first-class, separately-checked property so substance-present can no longer mask form-absent.

---

## 3. Application Protocol

When a frame applies, the protocol is: **produce the canonical-form artifact, OR document partial-form conformance with explicit rationale.** Never silently leave the form partial-or-absent — that is the degradation class § 2.3 guards against. The protocol's two named paths are exhaustive: any frame-governed output that is in neither path is incomplete.

### 3.1 When a frame applies

A frame applies to a piece of work when the work *is* an instance of that frame's domain — an architecture decision is being made (the ADR frame applies), a release is closing with a retrospective (the retro/lessons frame applies). Applicability is a judgment about whether the work belongs to the frame's domain, not a keyword match: a passing mention of "the ADR" in boilerplate does not make the ADR frame apply; *making an architecture decision* does. The registry (§ 4) enumerates the frames; the producing-stage column says where each frame's artifact is typically authored.

### 3.2 Produce the canonical-form artifact (default path)

The default path is to produce the frame's canonical artifact in its canonical form, using the frame's template (owned per § 4). This is the path that satisfies both properties from § 2 at once: substance applied AND form conformant. When the frame applies and producing the canonical artifact is proportionate to the decision, take this path — it is the default for a reason: it makes the work durable and citable with no further judgment required.

### 3.3 Document partial-form conformance with explicit rationale (the escape hatch)

When producing the full canonical form would be over-formalization — ceremony out of proportion to the work's decision value — the protocol's second path is to **document the partial-form conformance with explicit rationale**: state which parts of the canonical form are present, which are deliberately omitted, and *why* the full form would add ceremony without decision value. The rationale is the load-bearing part: a partial form without a stated reason is just the degradation class § 2.3 with a fig leaf. A partial form *with* a stated reason is a deliberate, auditable, reversible choice — the reviewer sees the form was considered and consciously scoped, not silently dropped.

This escape hatch is what keeps the discipline from becoming a mandate to over-formalize. It is the mechanism that distinguishes "we chose a lighter form for this reason" from "we forgot the form."

### 3.4 The over-formalization guard

The escape hatch in § 3.3 exists to prevent a specific anti-pattern: the **ADR-as-design-document** over-formalization — treating every minor or obvious choice as if it warranted the full canonical apparatus, so the frame's template becomes a ritual that adds ceremony without adding decision value, and authors either drown in boilerplate or quietly abandon the frame entirely. A canonical form that is mandated regardless of decision value trains people to game it or skip it; either outcome defeats the frame.

**Ceremony test (apply before producing the full canonical form):** *Would producing the full canonical form add ceremony without decision value here?* If yes → take the § 3.3 partial-conformance path and document the rationale. If no — the decision genuinely warrants the durable, citable canonical artifact → take the § 3.2 default path. The test is a judgment, made once per applying frame, and recorded (as the produce-vs-document verdict) so it is auditable. The guard cuts both ways: it stops the degradation class (form silently dropped) *and* the over-formalization class (form ritualistically over-applied).

---

## 4. The 7-Frame Registry

The registry enumerates the canonical-form frames. It **references** each frame's template owner by role and **inlines no template body** — the single-doc-references-templates boundary that keeps this one meta-discipline from becoming seven heterogeneous template libraries. Each frame row's *identity* (the frame number, its discipline domain, and its canonical-form artifact) is stable and addressable now, so a frame-template card can register itself against its row. The cluster is **seven frames, not eight** — a release-level decision-record rollup was considered as an eighth frame and its promotion was declined; the registry is intentionally seven. The owner cells for the frames whose templates are not yet authored are forward-pointers ("to be wired by that card"), not dangling references. No bare issue number appears in this table — owners are named by role; the numeric pointers live in the `## References` block.

| Frame | Discipline domain | Canonical-form artifact | Template owner (role) | Producing stage |
|---|---|---|---|---|
| F1 | Architecture decisions | Immutable markdown ADR | the markdown-ADR convention owner *(see References)* | Stage 5 Solutioning |
| F2 | Architecture evaluation | *(per split sibling — to be wired by that card)* | the architecture-evaluation frame split sibling under the KA-Discipline epic | per sibling |
| F3 | Technical design | *(per split sibling — to be wired by that card)* | the technical-design frame split sibling under the KA-Discipline epic | per sibling |
| F4 | Acceptance / test design | *(per split sibling — to be wired by that card)* | the acceptance/test-design frame split sibling under the KA-Discipline epic | per sibling |
| F5 | Stage-gate vocabulary | *(per split sibling — to be wired by that card)* | the stage-gate-vocabulary frame split sibling under the KA-Discipline epic | per sibling |
| F6 | Exception planning | *(per split sibling — to be wired by that card)* | the exception-plan frame split sibling under the KA-Discipline epic | per sibling |
| F7 | Retrospective / lessons | Per-release retro + lessons-learned register | the per-release retro & lessons-learned register owners *(see References)* | Stage 13 Close |

The F2–F6 row identities are fixed (frame number + domain); their owner cells are forward-pointers the split-sibling cards confirm when they author their templates. F1 and F7 have live template owners named in the `## References` block. Frame 8 is intentionally absent.

---

## 5. Composition and Wiring

This discipline is consulted by three surfaces; it does not enforce, it informs.

- **Decision-side conformance hook — `decision-discipline.md` § 2.1.2.** The Canonical-Form-Conformance Check sub-mechanism (a specialization of the Localization Check, Mechanism 1) is the decision-side enforcement hook. When a decision produces, or directs the production of, an artifact governed by a registry frame, that sub-mechanism localizes on the frame's canonical form: did the output produce the canonical artifact, or document partial-form conformance with rationale per § 3.3? The registry this discipline maintains (§ 4) is the surface that sub-mechanism consults to identify the frame; this discipline is the parent framework for the conformance dimension.

- **Per-stage pipeline outputs.** The pipeline shards whose stage *produces* a canonical-form-framed artifact cite this discipline's applicability in their output section: **Stage 5 Solutioning** (producer of the F1 ADR) and **Stage 13 Close** (producer of the F7 retro + lessons-learned register). A shard whose stage merely mentions or consumes a frame artifact — rather than producing one — does not cite applicability; a citation there would be noise. The two cited shards are the frame producers among the current frames with live templates.

- **Non-overlap with adjacent disciplines.** Canonical-form is the *artifact-shape* property; it does not duplicate `review-discipline-principles.md` (a missing canonical form is reported there as a review *finding* with severity and root cause — review owns the finding, this discipline owns the form definition) nor the evidence-grounding convention-canonicalization step (form conformance asks "does the artifact take its frame's canonical shape?"; convention canonicalization asks "which of several existing variants is the canonical one to follow?" — different questions on different objects). Cross-reference these; do not fold them together.

---

## References

This is the designated reference block — the only place a bare issue number appears, each line self-describing so the meaning survives a renumber.

- `#207` — the markdown ADR convention (Frame 1's canonical-form template owner)
- `#360` — the per-release lessons-learned register schema/template (Frame 7)
- `#361` — the per-release retro register schema/template (Frame 7)
- `#143` — close-class telemetry covering retro canonical-form conformance (Frame 7)
- `#145`, `#146`, `#147`, `#148` — content ADRs that consume the Frame 1 markdown-ADR canonical form
- `#1174` — the KA-Discipline epic (the inherited design source for this framework and the parent of the F2–F6 split-sibling template cards)
- Provenance: the v11.01 stage-design-quality audit finding **F-Release-3** (the canonical-form-application gap — substance-present / form-partial-or-absent across multiple phases and frames — that this discipline closes)

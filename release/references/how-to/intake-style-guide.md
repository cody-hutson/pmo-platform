<!-- reference-durability: allow-link -->
# Intake Style Guide

> Canonical reference for the intake/design boundary rule (5 tests) and the WHAT-vs-HOW principle. Templates link here; Triage references this in self-repair messages; agents load this as context when authoring or evaluating intake tickets.

**Source pattern:** `[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §C]` (5-test rule codification) and `§D` (over- vs. under-definition risk). **Companion docs:** `pipeline/stage-01-intake.md` §5 (two-tier intake protocol), `pipeline/stage-05-solutioning.md` §5 (Solutioning activation gate), `gate-criteria-spec.md` G1-04 / G1-05 (Triage gates), `best-practices-rubric.md` D4 (Intake/Design Boundary dimension).

---

## 1. Purpose

The PMO platform commits **WHAT** at intake (problem statement, constraints, observable outcome, acceptance criteria) and **HOW** at Stage 5 Solutioning (algorithm, data structure, file-internal pattern, pseudocode). The boundary exists because:

- **Compounding error.** A design committed at intake locks downstream stages into one path before Solutioning has assessed alternatives, blast radius, or feasibility. When the path turns out wrong, the cost to revert grows with every downstream commit.
- **Stranger-pickup readiness.** A fresh Claude Code agent (no session memory, CLAUDE.md + `core/rules/` loaded) must be able to triage, plan, and verify a ticket without asking the author a single question. WHAT-only intake makes that possible; mechanism-prescribing intake forces clarification round-trips.
- **Symmetric failure modes.** Under-definition (vague AC, no risks, no file pointer) is ~60× more common than over-definition in the corpus, but both are quality failures. The 5-test rule catches both at authoring time.

This doc gives ticket authors (agents and humans) a binary checklist they can apply before submitting an intake ticket — and gives Triage a reference point for self-repair guidance.

When an idea is not yet intake-ready, the `intake-desk` skill is the conversational front door (the intake funnel): it meets the idea at its altitude, identifies the work-item type and its place in the intake hierarchy, elicits the type- and level-appropriate fields, applies the 5-test rule live, and logs a well-formed item to the work tracker — never a scratch file.

`[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §C, §D]`

### Sanctioned idea-refinement surface

A half-formed idea — one not yet intake-ready (it fails one or more of the 5 tests below) — still has a sanctioned home; it is **never** developed as a draft / scratch file committed to the public repo (per [`core/rules/git-workflow.md` § Draft / scratch content](../../../core/rules/git-workflow.md)). Two surfaces:

1. **The issue tracker (primary).** Capture the nascent idea with `observation.yml` (the lightweight gap-capture tier), then promote it to `improvement.yml` once enough context exists to pass the 5-test rule. `intake-desk` is the conversational front door that meets the idea at its altitude and logs a well-formed item — refine *in the tracker*, not in a file.
2. **The git-ignored runtime tier (secondary).** Free-form exploration not yet tracker-ready lives in the operator-instance working space (`projects/`, `personal/` — the Layer-2 git-ignored tree), never as tracked corpus.

This is the *where* that complements the 5-test rule's *whether*: when an idea fails the tests, refine it on one of these surfaces until it passes, rather than committing a premature design or a scratch file.

---

## 1b. Template Selection by Work-Item Type (the deterministic first step)

Template selection is typed **before** it is tested: classify the work item's TYPE first — a deterministic fork — then apply the 5-test rule (§2) within the improvement/observation pair. The type fork is the first routing step every intake author (agent or human) executes; the 5 tests never re-litigate it.

| Work-item type — the finding is… | Discriminator | Template |
|---|---|---|
| **Bug** — "X is broken": observed behavior diverges from expected or documented behavior | Broken behavior exists today and is statable as reproduce / expected / actual | `bug.yml` |
| **Enhancement / change** — "we should add/change X" | A proposal with authorable substance (then apply the 5-test rule, §2) | `improvement.yml` |
| **Under-specified finding** — a gap or drift observed, but a full proposal is not yet authorable | T3/T4/T5 cannot be satisfied at authoring time (§2 Failure routing) | `observation.yml` |
| **Decision** — an architecture or design decision to record | The deliverable is the decision record itself | `adr.yml` |
| **Epic (methodology kind)** — a grouping container for a large body of work, under a resolved methodology | The intake scope resolves a methodology whose kind set declares an epic-equivalent grouping kind (per the kind-derivation contract in `operations/skills/intake-desk/references/type-map.md`); DoR-tier asks: outcome + scope | `epic.yml` (pack-projected kind form; stamps `type:epic`) |
| **Story (methodology kind)** — a user/operator-facing value increment, under a resolved methodology | The scope resolves a methodology declaring a story-equivalent commit-unit kind; DoR-tier asks: value + acceptance criteria | `story.yml` (pack-projected kind form; stamps `type:story`) |

**Decided tool-blind.** A determinate type classification is DECIDED, not asked: when the discriminators above resolve the type, the author selects the template and proceeds — the classification is never escalated to the operator as a clarifying question (`AskUserQuestion` or otherwise). Whether any question is warranted at all is governed by the AskUserQuestion-is-a-mechanism-not-a-trigger rule (CLAUDE.md § Universal Preferences); a rule-resolved classification is exempt from decision-class treatment per [`decision-discipline.md` § 3](../../../core/disciplines/decision-discipline.md). Only a genuinely indeterminate classification — the discriminators do not resolve it after being applied — is a real question, and it is asked as such: name the two candidate readings and the evidence gap, never a template menu.

**Relationship to the 5-test rule (§2).** Type is orthogonal to intake-readiness: the type fork picks the template; the 5-test rule then governs readiness within it — an enhancement that fails T3/T4/T5 demotes to `observation.yml` per §2 Failure routing, and Triage promotes it back when ready (§1 sanctioned-refinement surface).

**Relationship to the template-addition policy (§5b).** This section routes among the templates that exist; §5b governs when a new type-specific template may be added. When a new intake arm ships — a new template, or a type selector on an existing template, entering per §5b's scope-of-trigger note — it registers here as a new row (or an amended discriminator on an existing row) at its release. Registration is routing bookkeeping, not a speculative split. A resolved-methodology kind with no dedicated form emits on `improvement.yml` with its `type:*` label carried by the intake path (the interim-vehicle rule in `operations/skills/intake-desk/references/type-map.md` § Kind ↔ label ↔ level binding); dedicated kind forms join the chooser only through this registration convention.

**Single source.** This section is the one authoritative home for the type→template rule (per `core/standards/duplicate-source-discipline.md`): templates and governance files link here rather than restating the fork, and a template's chooser description carries at most a one-line discriminator.

`[SOURCE: consolidation of the type fork previously scattered across .github/ISSUE_TEMPLATE/bug.yml's description and CLAUDE.md § Continuous Improvement — single-sourced here per core/standards/duplicate-source-discipline.md §1(2)]`

---

## 2. The 5-Test Rule

Apply these 5 tests in order at authoring time. Each has a binary answer.

**Rule:** If all 5 pass → intake-ready. If any fails → defer to Stage 5 Solutioning, split the ticket, or use `observation.yml` per the routing guidance below.

| # | Test question | Pass if... | Rubric mapping |
|---|---|---|---|
| **T1** | **Atomic?** Could this be reverted by a single `git revert`? | Yes — this is one cohesive change. If 2+ unrelated changes, split. | D8 (scope fit) |
| **T2** | **Determinate design?** Is there a single reasonable implementation, or multiple viable designs? | Single OR design boundary is deferred to Solutioning explicitly. If author is secretly assuming a design without naming it, fail. | D4 (boundary), `pipeline/stage-05-solutioning.md` §5 Phase 0 Activation criteria |
| **T3** | **Verifiable AC?** Can a fresh Claude Code agent check each AC predicate by reading a file, running a command, or inspecting an output? | Yes — each AC is a predicate. If any AC is a vibe ("works correctly", "improves flow"), fail. | D3 (AC verifiability) |
| **T4** | **File pointer?** Does Proposed Change name ≥1 specific file/section OR explicitly say `[ASSUMPTION – CONFIRM] TBD — identified in Planning`? | Yes — directional or deferred-with-marker, not silent. | D7 (deps/files), `gate-criteria-spec.md` G3-03 |
| **T5** | **Risk surfaced?** Are the known risks, cross-issue conflicts, or concurrent-work conflicts named? (Even a one-liner: `[ASSUMPTION – CONFIRM] may conflict with #N if both land in same release.`) | Yes — risks named if they exist, OR explicit "None identified". Silent = fail. | D5 (compounding risk) |

**T4 and §4c are different questions.** T4 tests the *presence* of a file pointer; §4c (Scope-Altitude Consistency) tests whether that pointer resolves to **one determinate set** and whether the item's asserted outcomes are **producible from it**. A ticket can pass T4 and still fail §4c. §4c is not a sixth test — it is a body-quality rule enforced at Triage, exactly as §4b is.

### Failure routing

- **If T1 fails:** Split into multiple tickets with a parent tracking issue. The author commits the split rationale. Operationally, Triage executes the protocol at [fission-convention.md](../protocols/fission-convention.md).
- **If T2 fails:** Do not commit a design at intake. Add `[ASSUMPTION – CONFIRM]` labels on any design assumption and note "HOW deferred to Stage 5 Solutioning." The ticket is intake-ready; Solutioning will activate.
- **If T3, T4, or T5 fails and the author cannot fix:** The author uses `observation.yml` (per Stage 1 §5 Path A two-tier protocol) and explicitly stages the finding as a placeholder. Triage promotes to `improvement.yml` when enough context exists.

`[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §C The 5 tests]`

---

## 2c. Acceptance is not a default (the anchor-relation doctrine)

The 5-test rule (§2) governs whether an idea is **well-formed enough to file**. It does **not** decide whether the idea should be **accepted** — that decision happens at Stage 2 Triage, and its default answer is not "yes."

**No intake issue is accepted by default.** A well-formed ticket earns its place in the pipeline only by relating to a **named existing architectural anchor** — an ADR, an initiative/epic, a governing standard, or a named discipline — and being compatible with it. An idea that is free-floating (does not relate to any existing anchor) is **expected to be Rejected** at triage. That Reject is a correct, first-class outcome — not a triage failure, and not a gap in your intake. Rejecting a good-looking but anchor-less idea is the pipeline working as designed: it protects the platform's safety, stability, scalability, and maintainability from drift-by-accretion.

**Volume does not accrue authority.** The auto-logging rule asks agents to file an issue on every detected gap. That is a *demand* signal, not an *acceptance* signal — the two are deliberately separated. An idea does not become worth building because it was filed, filed repeatedly, or filed by an agent. The acceptance counterweight is keyed to provenance and blast radius, not to how the idea arrived.

**Elevated rigor — net-new builds and sweeping/cross-cutting changes.** The highest-rigor acceptance cases are:

- **Net-new builds** — a new skill, a new Layer-1 structure, or a new top-level capability.
- **Sweeping / cross-cutting changes** — multi-surface or governance-touching changes.

For these, acceptance requires an **explicit anchor** *and* a one-line **blast-radius / reversibility note** before the idea is taken on. "It seemed useful" is not an anchor.

**Agent-authored / auto-logged intake carries no acceptance presumption.** An issue authored by the agent auto-intake path is marked by a provenance marker (`<!-- provenance: agent-authored -->`, emitted per [`pipeline/stage-01-intake.md`](../pipeline/stage-01-intake.md) §5/§6) and, together with the net-new/sweeping subset, is the population where the acceptance determination is required at triage. The marker is an acceptance-**scrutiny** signal only — never a trust signal (trust is a separate, author-association question).

**Where this is enforced.** The acceptance determination is the Stage-2 **Acceptance-Fit Determination (A4.6 / gate G2-13)** — see [`pipeline/stage-02-triage.md`](../pipeline/stage-02-triage.md) § Acceptance-Fit Determination (A4.6) and [`gate-criteria-spec.md` G2-13](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness). It is **scoped** (fires only on the agent-authored or net-new/sweeping subset) so routine operator-authored tickets are not re-litigated, and it **enforces from v3.94** — on that scoped subset a missing anchor determination blocks the Approve verdict (operator-ratified 2026-07-25 per ADR-093; the v3.94 introducing release is itself exempt). As an intake author, internalize the doctrine now: state the anchor your idea relates to in the body, or expect an anchor-less idea to be Rejected.

---

## 2d. Section-anchor citations

A precondition that cites a file **plus a section anchor** cites a section that **exists in that file at authoring time**. Write the anchor only after looking at the target's headings — not from memory of how that document is usually organized, and not from how a sibling document is organized.

**An inherited citation is re-verified, never carried forward on the strength of looking precise.** When you copy a precondition from another ticket, a prior release plan, or an earlier comment in the same thread, the file may have been restructured since it was written. A section number is the most confident-looking thing in a ticket body and the least self-checking: `§ 4.1` reads as though someone verified it, and nothing about a stale one looks stale. Open the file and confirm the section is there. If it is not, cite the section that now carries the content rather than deleting the anchor — a bare file reference sends every future reader through the whole document.

**A citation into a file outside the tracked repository is marked as such.** Operator-local files, generated artifacts, and anything git-ignored cannot be resolved by any reader who is not you, and cannot be resolved by any check. Say so inline — *"(operator-local, not tracked)"* — so a reader who cannot open it knows immediately that the problem is their checkout and not their search.

**Prefer the section's number and its name together** (`§ 4.1 Operand resolution`) over the number alone. If the document is renumbered, the name still locates the content; if the section is renamed, the number still does. Either half surviving is the difference between a citation that degrades and one that dies.

**Where this is surfaced.** Numeric anchors in open issue bodies are resolved against their target's actual headings by the **Section-Anchor Resolution (A4.8)** determination at Stage 2 Triage, and by `deploy.sh` **Check 71**. Both are **advisory and report-only** — they surface a citation that does not resolve, they never block. Neither covers every citation form: the predicate models numeric anchors behind five prefixes and declares the classes it does not model, with counts, in its own header. Treat a clean run as *"nothing was found in the modelled classes"*, never as *"every anchor here is good."*

---

## 3. Applied Examples

The 5 tests applied to 5 sampled tickets spanning the quality spectrum (from the audit corpus). All 5 verdicts match the weighted-score classification directionally — the rule routes tickets *before* they enter the intake stream.

| # | Ticket | T1 | T2 | T3 | T4 | T5 | Verdict | Weighted score |
|---|---|---|---|---|---|---|---|---|
| Ex 1 | [Protocol]: Collective review gate for batched ticket processing | ✓ atomic | ✓ design deferred to Solutioning | ✓ predicates named | ✓ `pipeline/stage-05-solutioning.md` ref | ✓ cross-issue risks flagged | **INTAKE-READY** (all 5 pass — file as `improvement.yml`) | 4.27 (Strong) |
| Ex 2 | [Protocol]: Evaluate MarkItDown MCP | ✓ atomic spike | ✗ spike = multiple designs by definition | ✗ AC is research question | ~ directional | ✗ risks not surfaced | **DEFER to Stage 5** (or re-file as research spike with T3/T5 as research questions) | 2.30 (Weak) |
| Ex 3 | [Skill]: No Release Manager Mode 2 deployment execution skill | ✗ "Mode 2" is a whole skill | ✗ no design committed | ✗ no testable AC | ✗ no files | ✗ no risks | **OBSERVATION-TIER** (use `observation.yml` — lightweight 3-question form) | 1.76 (Weak) |
| **Ex 4** | [Skill Update]: PMO Role Skills Suite — Build & Deploy 18 Skills | ✗ 18 skills = 18 tickets | ~ per-skill design would vary | ~ AC per-skill | ~ per-skill | ~ per-skill | **SPLIT** into 18 proposal tickets + 1 tracking issue | 2.70 (Adequate — D8=2 catches scope failure) |
| Ex 5 | fix: deploy.sh CHANGED_PACKAGES unbound variable (PR commit note) | ✓ atomic | ✓ design trivial | ✗ no AC (already done) | ✓ specific file | ~ no risks | **NOT AN INTAKE TICKET** — PR commit note; should have been closed immediately | 1.61 (Weakest in corpus) |

### How to read the verdicts

- **INTAKE-READY** → file as `improvement.yml`, all required fields populated, lands in Proposed.
- **DEFER to Stage 5** → ticket may be intake-ready *if* author explicitly marks design `[ASSUMPTION – CONFIRM]` and lists Stage 5 as the resolver; otherwise re-file as research spike.
- **OBSERVATION-TIER** → file as `observation.yml` (3-question form per Stage 1 §5 Path A), lands in Proposed with `observation` label, awaits Triage promotion.
- **SPLIT** → halt authoring, create parent tracking issue + N child issues, file children as separate intake tickets.
- **NOT AN INTAKE TICKET** → PR commit note, closed bug, or already-resolved item; do not file. Use the resolution channel that already applies (PR description, commit log, etc.).

`[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §C Test applied to 5 sampled tickets]`

---

## 4. Anti-Patterns

Over-definition occurs when the author commits a HOW at intake before Solutioning has assessed it. Each anti-pattern below has a rewrite in WHAT framing. The signal is the same in every case: pseudocode, named implementation patterns, line-level surgical directives, or algorithm-step descriptions belong at Stage 5, not Stage 1.

### Anti-pattern A — Surgical line-level directive

**Over-specified (T2 fails):**
> "Change line 42 of `auth.ts` to `const FOO = bar` — this is the bug."

**Rewrite (WHAT framing):**
> "Authentication header parsing returns `undefined` when the upstream proxy strips the `Authorization` field. Affected: `auth.ts` (the header-resolution path; specific line(s) identified in Planning). Acceptance: a request that arrives without `Authorization` returns `401` rather than `500`."

**Why it matters:** Line 42 may shift before Engineering picks the issue up. The mechanism (`const FOO = bar`) is one of several viable patches — Solutioning evaluates whether the right fix is at the parser, the middleware, or the proxy config.

### Anti-pattern B — Naming an implementation pattern

**Over-specified (T2 fails):**
> "Use the visitor pattern here to walk the AST."

**Rewrite (WHAT framing):**
> "AST traversal must support pluggable per-node behavior so that the linter, the formatter, and the symbol-resolver can share traversal logic. Constraint: traversal API is stable across the three callers. Acceptance: each caller subscribes to ≥1 node-type handler and the same AST instance can be walked by all three without re-parsing."

**Why it matters:** "Visitor" is one of several pluggable-traversal patterns (visitor, iterator, fold, dispatch table). Solutioning chooses among them given the codebase's existing conventions, performance constraints, and team familiarity.

### Anti-pattern C — Describing the algorithm

**Over-specified (T2 fails):**
> "Loop over the array, filter by status, then map to display strings."

**Rewrite (WHAT framing):**
> "The dashboard's status panel must show only active items, formatted per the display schema. Source: the in-memory items collection. Acceptance: inactive items are not rendered; rendered items match the display-schema field set; render time is bounded (target: ≤ 50ms for 10k items)."

**Why it matters:** The author has prescribed array-loop-filter-map. Solutioning may choose a memoized selector, a database-side filter, or a streaming reducer based on the data size and update cadence — the WHAT framing doesn't constrain that choice prematurely.

### Anti-pattern D — Temporal-window AC (verifiable only post-close)

**Over-specified (T3 fails — predicate cannot be checked at merge time):**
> "Acceptance: 10 tickets authored within 30 days show rescored D ≥ 3.5."

**Rewrite (WHAT framing):**
> "Acceptance: the rewritten tier-selection test reads correctly per the symmetric content-shape routing rule (verify by reading the OPERATIONS.md § Continuous Improvement Path A subsection). Monitoring (post-close, in Notes): re-run the tier-distribution query 30 days after merge; target band 20-50% observation-tier share per #N follow-up commitment."

**Why it matters:** ACs that require a time-window (30-day rescore, 60-day adoption survey, post-deploy quarterly review) cannot be verified at Stage 8 QA sign-off — they hold open the merge gate for a duration the release lifecycle cannot afford. The fix is to **split the predicate at the AC↔Notes boundary**: the AC asserts what is observable at merge (file state, rule text, test pass); the Notes field carries the **monitoring commitment** as a post-close observable (one-line "Monitoring: [observable + window]" entry). Triage promotes monitoring commitments to follow-up issues per the R2 DEFERRED convention referenced in this issue's source (release retrospective).

### General test for temporal-window violation

If any AC bullet contains any of these phrasing patterns, T3 fails on temporal grounds and the AC should be rewritten per the Anti-pattern D shape:

- `within N days` / `within N hours` (post-merge)
- `over the next N [day|week|month]`
- `N-day rescan` / `N-day re-run` / `N-day re-review`
- `adoption-over-time` / `usage-over-N-days`
- `[metric] held above X for N consecutive [day|week|month]`
- Any predicate scoped to a post-merge measurement window

Rewrite using the formula: **state the merge-time observable in the AC; restate the post-merge observable in Notes as a "Monitoring:" line; if a follow-up tracking issue is intended, name it.**

### Anti-pattern E — Hedging by offering mechanism choices during drafting

**Over-specified (T2 fails — at the drafting interaction, not in the ticket text):**
> "Should the template have fields A, B, and C?" / "Which stage anchor should this fire at — 8, 9, or 12?" / "Pick one: sidecar file, central manifest, or exclude."

**Rewrite (apply the framework, don't ask):**
> When the WHAT/HOW boundary already resolves the question, apply it and move on. State the capability requirement as an acceptance criterion and, where a design choice exists, append "mechanism deferred to Solutioning." Surface a genuine open question only when the framework does not resolve it.

**Why it matters:** Asking the author or operator to pick among mechanism-level options *during intake drafting* is a HOW question dressed as a design request — it offloads Solutioning's job onto the wrong audience at the wrong stage, and pre-bakes a choice without the evidence Solutioning would bring. The signal is a SHAPE question: field lists, timing/stage selection, storage-format options. When the guidelines are clear, apply them; do not hedge.

**Exception:** A mechanism choice already committed in an upstream dependency's spec (e.g., frontmatter fields established by a prerequisite) MAY be extended at intake without counting as mechanism-creep — you are applying a committed convention, not picking a new one.

### Anti-pattern F — Naming the mechanism inside an acceptance criterion

**Over-specified (T2 fails inside the Acceptance Criteria field):**
> "Acceptance: `test_existing_suite.py` executed by a CI job and scoped to `the_generator.py`."

**Rewrite (WHAT framing):**
> "Acceptance: predicate: the generator is exercised by a CI job; method: a CI-run test imports the generator and asserts on its output."

**Why it matters:** the AC named the *instrument* (one specific test file) rather than the *observable* (the generator is exercised in CI). The pattern this rule comes from was a security-hardening slice that brought a generator under CI through a **purpose-built** test importing it, rather than through the pre-existing suite the AC had named — fully delivering the intent, yet the literal wording read as a partial miss and the criterion had to be graded with interpretation. An acceptance criterion states the observable the system must exhibit; it does not prescribe the instrument that produces it, so a superior implementation cannot grade as a miss.

**Why the existing controls did not catch it:** this is a missing *pattern*, not a missing *field*. The over-definition patterns below catch pseudocode, named design patterns, line-level directives, file-**internal** naming, and algorithm description — a bare file name matches none of them, in any field, so the same string passes the test in a Proposed Change today. The new sixth bullet is what closes the gap; extending the test's field scope is what makes it reachable from an acceptance criterion. Both are required, and neither substitutes for the other.

**The line to hold:** an AC names the artifact **whose state is asserted**, not the **instrument that produces** that state — *unless the instrument is itself the deliverable* (an AC on a build artifact, or on a script being authored, legitimately names that file). This does not weaken verifiability: an intent-shaped AC still carries a checkable predicate plus a stated verification method, which is the behavioral/domain AC shape the Triage readiness gate already accepts.

**Cutover:** applies to acceptance criteria authored after this rule lands. Existing open ACs are not re-graded.

### General test for over-definition

If the Proposed Change **or any Acceptance Criterion** contains any of these, T2 fails:
- Pseudocode (`for x in xs: if x.foo: ...`)
- Named patterns without `[ASSUMPTION – CONFIRM]` (visitor, factory, observer, etc.)
- Line-level surgical directives ("change line N", "insert at line N+5")
- File-internal naming (specific function names, internal section anchors as design choices not surfaced markers)
- Specific algorithm description ("loop over", "filter then map", "reduce to")
- A named instrument inside an acceptance criterion where the observable is the outcome rather than the instrument (per Anti-pattern F) — unless the instrument is itself the deliverable

Rewrite using the formula: **state the observable outcome the system must produce, the constraints that bound it, and the directional file pointer — let Solutioning choose the mechanism.**

`[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §D Over-definition]`

---

## 4b. Usability ACs for Capability-Class Items

§4 governs **over**-definition — a HOW committed too early. This section governs the opposite failure: an AC set that is fully well-formed and still cannot tell whether the thing works.

**The failure.** A capability can pass every acceptance criterion and all of CI while shipping **dormant** — verified structurally present, but not actually usable. An AC set that asserts only NOUNS ("a roster template ships", "the four consuming skills reference the graph view", "the schema changed") is structurally incapable of catching a missing activation or wiring path: every assertion is true, and on a fresh install the capability does nothing, because the file the skills are instructed to read is never seeded. Presence ACs are necessary; they are not sufficient.

**The rule.** A **capability-class** work item carries at least one **usability AC** — an observable end-to-end behavior the capability performs AFTER install/deploy, stated as a VERB exercised against a named, populated fixture — in addition to its presence ACs. The usability AC is additive: nothing about the presence ACs changes. An item that is not capability-class names its exempt class instead. The enforcement surface is the Triage readiness gate criterion **G1-05b branch (ii)** in [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) § Gate 1 and its § Capability-Class Usability-AC Requirement block, re-run at Stage 4 pre-plan crisping.

**The doctrine below is duplicated from the enforcement surface on purpose, and that duplication is registered.** The C1–C3 limb rows, the E1–E5 exempt-class rows, the anti-patterns, the required AC shape, and the U1–U5 conformance tests are also carried, stated rather than cited, by `gate-criteria-spec.md` § Capability-Class Usability-AC Requirement (referenced from G1-05b branch (ii)). The pair is registered as a per-domain **prose exemption** under [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md) §1 condition 3; the exemption itself — its rationale, the reason conditions 1, 2 and 4 are unavailable, and the co-edit obligation it imposes — is documented once, in the owning principle at [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md) § Capability-Class Usability-AC Requirement (referenced from G1-05b branch (ii)), and is not restated here. In short: that schema **enforces** the rule and this guide **instructs** an author how to satisfy it, so each file has to read standalone. Two consequences bind an editor of this section. **An edit to any doctrine line below must land on both surfaces in the same change** — nothing mechanically detects a one-sided edit. And the **verdict language is not this file's to carry**: the set-level rejection rule, the Layer-B coverage note, and the G1-05b self-repair branches live on the enforcement surface only, exactly as the worked pair at the end of this section lives here only.

### Is it capability-class? Three limbs, all must hold

| Limb | Question | Not satisfied when |
|---|---|---|
| **C1 — actor** | Is there a named actor — an agent following the platform's own instructions, a script / check / hook, a CI job, or an operator executing a documented procedure — that will *do* something because of this change? | Only a **reader** is affected |
| **C2 — trigger** | Is there a named runtime moment that fires it — a session start, a deploy run, a gate evaluation, a PR event, a stage entry, a command invocation? | Nothing reads it at runtime; adoption depends on someone remembering |
| **C3 — observable** | Is there something a third party could witness after install — output, a state change, an emitted artifact, a verdict, a blocked action — that is **not** the presence or content of the edited file itself? | The deliverable **is** the artifact |

**capability-class = C1 ∧ C2 ∧ C3.** Read the limbs ***ex ante*, against the item's design** — does the design *name* an actor, a runtime trigger, and a witnessable observable? — never against observed runtime. Whether the trigger actually fired is precisely what the usability AC exists to test, so folding that observation back into the limbs makes the test circular.

Read that way, the motivating failure satisfied **all three**: C1 (four skills instructed to read the roster), C2 (each reads it at its own named runtime moment), C3 (a name resolves to a person record). It *was* capability-class and owed a usability AC — and what went wrong was not a limb but the **delivery of C2's precondition**: nothing seeded the roster on install, so the named trigger never fired. The reading to avoid is the *ex post* one — "nothing fired, therefore no C2" — which routes this very case to the E3 exempt class below (keyed to C2) and exempts it. Nor does the conjunction earn its place by being the only predicate that would have caught this item: a looser, **disjunctive** predicate would have caught it too, since C1 and C3 hold on either reading. It earns its place by keeping genuine reference-content, refactor, bookkeeping, and spike work out.

**On the word `capability-class` here:** it classifies a **work item at intake**. It is not the *Release Class* of a whole release, and it is not the generic "class of capability a solution targets" used by the Stage-5 extend-before-create criterion.

### Exempt classes — a closed list, each named by the limb it does not satisfy

| # | Exempt class | Limb | One-line test |
|---|---|---|---|
| **E1** | **Reference-content change** — doc, standard, discipline, ADR, release note, comment, prose or naming edit whose whole effect is what a **human** reader reads. **An agent-loaded instruction file is not exempt under E1 merely because its effect is textual** — if a named agent loads it at a named runtime moment and behaves differently, test it against C1 ∧ C2 ∧ C3 rather than claiming E1. | C1 | Nothing **runs** differently after install |
| **E2** | **Behavior-preserving refactor / relocation** — move, rename, extraction, dedup, reflow, reference repair, carrying a declared no-behavior-change invariant | C3 | The correct AC is a **must-NOT-change** assertion |
| **E3** | **Governance-internal rule with no runtime trigger** — doctrine or protocol prose consumed at human or agent judgment time, with no gate, check, hook, or command reading it | C2 | No executor reads it |
| **E4** | **Tracking / bookkeeping** — an issue-body edit, label / milestone / epic hygiene, backlog restructuring, corpus-metadata reconciliation | C1 + C2 | The mutation is to the tracker, not to the platform |
| **E5** | **Spike / analysis / decision record** — research, audit, gap analysis, or a decision whose deliverable is the finding or the record itself | C3 | The output is knowledge, not behavior |

The list is closed — extending it is a governed change, not an authoring choice. Six rules keep it from reading as a general escape hatch:

- **A mixed item is capability-class.** An item that is mostly documentation and partly a new hook is capability-class **for the hook**. The test is whether the triple holds anywhere in the item, not whether it holds for the majority of the diff.
- **"It only changes a default or a config value" is not an exemption** when a runtime actor reads that value — all three limbs hold.
- **"It ships warn-mode" is not an exemption.** A warn-mode check still runs and still emits; only the authority of its verdict is reduced.
- **E3 is an exemption from the usability AC — never a finding that the rule will be adopted.** A rule expected to change behavior should acquire a trigger (a gate, check, hook, or named stage step) rather than claim E3. E3 exempts on the absence of a runtime trigger — the same limb (C2) whose *ex ante* satisfaction made the motivating failure capability-class — so claiming it without justifying the absence hands that failure the exemption it must never get, reproducing it one layer up.
- **Silence is not an exemption.** An AC set with neither a conforming usability AC nor a named exempt class is what Triage returns to the author, per the G1-05b (usability-AC coverage) self-repair.
- **A passing discrimination arm at the check's default invocation does not discharge `U5`.** A shipped count-vs-structure check carried a genuine two-armed fixture harness whose must-not-flag arm ran with the baseline disabled. The over-firing defect lives where a path-scoped invocation meets a *loaded* baseline: the stale set is computed against the full baseline while only the scoped subset is scanned, so every baselined entry outside the scope reads stale. **Both parameters were exercised individually; their combination never was.** The arm was real, non-vacuous, and blind — it ran on the content axis while the defect lived on the scope-by-comparison-set axis. Enumerate the parameters, not the fixtures.

### The shape of a usability AC

A usability AC rides the behavioral/domain AC pattern the Triage gate already admits — an outcome declaration paired with a `method:` declaration — with the outcome anchored after install:

```
- [ ] predicate: after a fresh install/deploy, <actor> <verb-phrase> against <named, populated fixture>,
      producing <stated observable>; method: <the exact invocation or procedure that exercises it,
      and the observable that must be seen>
```

Four conformance tests, plus a conditional fifth. A bullet is a usability AC only when all four hold — and, where the capability is a mechanical check, when `U5` additionally holds:

| # | Test | Rejects |
|---|---|---|
| **U1** | **Post-install anchor.** The predicate names the post-install / post-deploy / fresh-session / first-run moment. | An assertion true only in the author's working tree |
| **U2** | **Actor + action verb.** The predicate names an actor and an action it performs. Verbs of existence — `exists`, `ships`, `is present`, `contains`, `includes`, `has`, `references`, `is defined`, `is documented` — do not satisfy U2 in the predicate position. | "a roster template ships" |
| **U3** | **Named, populated fixture.** The predicate names the concrete input or state the behavior runs against. A behavior asserted against no fixture, or an empty one, does not satisfy U3. | "an agent can resolve a name" — against which roster? |
| **U4** | **Observable is not the artifact.** The stated observable is something other than the presence or content of the file(s) the change edits. | "the file contains the rule" |
| **U5** | **Discrimination arm at the check's own parameter surface.** *Conditional — fires only when the capability is a **mechanical check**: a script, lint, hook, gate, or CI job that emits a finding.* Three limbs, all required. **(1)** The predicate names a **near-miss input the check must NOT flag** — one differing from a true positive only in the property being tested. **(2)** It states that arm's expected **zero** as part of the stated observable, rather than leaving the zero implied. **(3)** It exercises that arm at **each parameter of the check's own declared invocation surface that narrows the examined population or changes the comparison set** — not merely at the scopes the other criteria happen to mention, and not merely at the check's default invocation. This binds the specificity arm defined at `core/disciplines/review-discipline-principles.md` § 8 **PV-2c** to the AC set; that arm's definition, its PASS condition, and its vacuous-arm rider live there and are not restated here. | A must-flag fixture set with no must-not-flag member; "no false positives" asserted in the abstract, which is unfalsifiable; a discrimination arm exercised only at the check's default invocation |

**U5 limb 3 — the deferral rider for a card that ADDS a check.** Limb 3 is graded **as written at intake** on a card that **modifies** an existing check: that check's invocation surface is already declared and is enumerable from its own argument parser. On a card that **adds** a check, limb 3 is structurally unauthorable at intake — a check that does not yet exist has no declared invocation surface to enumerate, and the enforcement surface is often still an open design question at that moment. Such a card satisfies limb 3 by naming the **intended** narrowing parameters, or by marking the enumeration `Stage-5-deferred`; the explicit enumeration then **binds at Stage-5 exit and is graded there**, against the design spec that fixes the invocation surface. **Limbs 1 and 2 are graded at intake in both cases.** A `Stage-5-deferred` marker that is never discharged at Stage-5 exit is an unsatisfied U5 — not an exemption.

**U5 cutover — the obligation binds forward, not backward.** U5 applies to work items entering intake **after** the release that introduces it (`triage-and-backlog-instrumentation`); items authored before that release, and items already in flight when it shipped, are graded against the `U1 ∧ U2 ∧ U3 ∧ U4` conjunction alone and are not retroactively bound. The introducing release itself is exempt: it *produces* U5, so its own cards were authored before the obligation existed and could not have been written to it — a rule that bound them would be unsatisfiable by construction, and grading them against it records an authoring artifact as a failure rather than a defect. The release is named here by **slug** and not by version — the version binds only at the Stage-12 atomic claim (ADR-092), so a version stem written into this rule would be a guess when authored and wrong after any re-sequencing.

**Writing U5 as an author, not as a grader.** Open the check's argument parser and list every parameter that changes *what it looks at* or *what it compares against* — a path or root filter, a file-list input, an exemption toggle, a baseline on/off switch. That list is your obligation. Then pick one input that a correct author would produce and that differs from a genuine defect in exactly the property the check tests, and assert it returns zero **at every one of those parameters**, not just at the bare invocation. If you cannot name such an input, you do not yet know what the check discriminates.

**U2 does not change what a presence AC may say.** The Triage gate's file-path + state-verb AC pattern (`contains` / `includes` / `has`) stays valid and unchanged. U2 constrains only the additional usability bullet.

### Worked pair

**Presence-only — the dormant-capability shape:**

> - [ ] Verify that the people-roster template ships in the templates directory
> - [ ] Verify that the four consuming skills reference the graph view
> - [ ] Verify that the schema carries the new person entity

Every bullet is true, and nothing exercises the capability. It shipped inert.

**Rewritten — presence ACs retained, one usability AC added:**

> - [ ] Verify that the people-roster template ships in the templates directory
> - [ ] Verify that the four consuming skills reference the graph view
> - [ ] Verify that the schema carries the new person entity
> - [ ] predicate: after a fresh install into an empty workspace, an agent resolves an owner name to its person record from the seeded roster and returns that record's tier; method: run a fresh install, then invoke the resolution path against a roster seeded with two named people and one unknown name — the two resolve with their tier and the unknown returns not-found.

The fourth bullet is the one that catches a missing seed step. U1: after a fresh install. U2: an agent *resolves*. U3: a roster seeded with two named people. U4: the returned record and its tier, not the template file.

### Worked pair — a mechanical check, where U5 additionally fires

**Capability-only — the over-firing shape:**

> - [ ] predicate: after a fresh deploy, the lint flags the seeded miscount fixture, producing a non-empty finding list; method: run the fixture harness and assert the finding list is non-empty.

This satisfies U1 through U4 and is still blind. Nothing in it contradicts a lint that flags *everything* — and nothing exercises the flags the check itself accepts.

**Rewritten — the discrimination arm added, at each narrowing parameter:**

> - [ ] predicate: after a fresh deploy, the lint flags the seeded miscount fixture **and returns exactly zero findings against the near-miss fixture whose stated count is correct**, at both the whole-tree invocation and the path-scoped invocation **with the baseline loaded**; method: run the fixture harness at each of the two invocations and assert the must-flag set is non-empty and the must-not-flag set is exactly zero at both.

The near-miss is named and differs from a true positive in exactly one property — the count is correct rather than wrong. Its expected zero is stated, not implied. And the arm runs at both invocations, including the path-scoped one with the baseline loaded, which is where the real over-firing lived. Had the card carrying this check been authored to U5, the parameter enumeration alone would have surfaced the untested combination.

**If the card ADDS the check rather than modifying one**, the same bullet is authored with the invocation list marked `Stage-5-deferred` — or with the intended narrowing parameters named — and the enumeration is filled in and graded at Stage-5 exit, once the design fixes what the check's argument surface actually is.

**An exempt example.** A ticket that corrects an over-broad leading sentence in four reference files does not satisfy C1 — only a reader is affected. Its AC set carries no usability AC and names its class instead: `Exempt: E1 — reference-content change.` The one caution: if those files are loaded by an agent at a named runtime moment, E1 does not apply on the strength of the change being textual — test the triple first.

`[SOURCE: a shipped people-graph release whose acceptance criteria and CI all passed while the capability was dormant on a fresh install — the systemic root of that release's remediation epic. This section is the rule that prevents recurrence.]`

---

## 4c. Scope-Altitude Consistency

§4b governs an AC set that cannot tell whether the thing works. This section governs a different well-formed-but-insufficient failure: an item whose **asserted outcome** sits at a higher altitude than its own **declared scope** can reach.

**The failure.** A ticket promises a behavioral end-state that the files it says it touches — or the fix directions it says are acceptable — cannot deliver. Nobody errs at any single step: the builder delivers precisely what the declared scope specified, dev testing correctly grades the delivered change PASS, and acceptance review correctly grades the criterion PARTIAL. The defect is in the ticket's **internal consistency**, and no gate examines that. It surfaces at acceptance review — the most expensive place in the pipeline to find it — and it is the dominant root cause behind a release whose PARTIALs all traced to intake authoring rather than to build quality.

**The rule.** A work item's asserted outcomes must be **producible from its own declared scope**, and that declared scope must resolve to **one determinate set**. Two failure directions, both authoring defects:

- **Indeterminate scope.** The declared scope offers alternative fix directions, or pairs a deferral marker with concrete surfaces named elsewhere in the body, or is absent altogether — while a graded acceptance criterion asserts an outcome whose grading *depends on which reading is taken*.
- **Unreachable outcome.** The declared scope is determinate, and an asserted outcome still requires a surface no member of it can be.

**Where this is enforced.** The check is the Stage-2 **Scope-Altitude Determination (A4.7 / criterion `SA-G1`)** — see [`pipeline/stage-02-triage.md`](../pipeline/stage-02-triage.md) § Scope-Altitude Determination (A4.7). It is **advisory and non-gate-blocking**: it is not a `gate-criteria-spec.md` registry criterion, it rides the existing A6 `feasibility flags` field, and no path from it blocks triage intake. Its output is a prompt to the author, not a rejection.

**The predicate lives at the enforcement point, not here.** The two limbs, the SA1–SA3 containment bar, the operand-resolution rules, and the closed non-fire guard list N1–N7 are stated once, in the A4.7 block — this section cites them rather than restating them, so there is no doctrine pair to keep in sync. One line **is** carried on both surfaces on purpose, because it is the teachable core of the rule and an author needs it at authoring time: the agent-vs-machine discriminator below. That single pair is registered as a per-domain prose exemption under [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md) §1 condition 3 — an edit to it must land on both surfaces in the same change.

### The teachable rule: agent-executed vs. machine-executed

A markdown governance file **can** produce an *agent-executed* outcome — "the stage verifies X", "the reviewer applies Y" — because the executor is an agent reading it. It **cannot** produce a *machine-executed* outcome — "CI fails", "the hook blocks the commit", "the required check goes red" — which needs a workflow, a script, or a hook. Conflating the two is the most common way an assertion outruns its scope, and the most common way a reader wrongly claims it has.

### Two shapes to check your own draft against

**Shape 1 — forked scope.** The declared scope names alternative fix directions while the asserted outcome is a single, unconditional end-state a graded criterion will check.

> **Declared scope:** `schema §N (decision enum) **OR** stage spec §M (emission spec) **+** the validating tool`
> **Expected Behavior:** "…the two specs agree on the enum, **and** the codified audit row can be written."

The fix directions are alternatives; the assertion is unconditional. Whichever fork is built, the other half of the assertion may still be unreachable — so an acceptance grader can render PARTIAL against a build that did exactly what the ticket authorized.

`[SOURCE: a shipped schema↔stage-shard drift bug whose declared scope offered two alternative fix directions while its Expected Behavior asserted the end-state unconditionally; dev testing graded the delivered change PASS, acceptance review graded the criterion PARTIAL, and no individual actor erred.]`

**Shape 2 — scope carried in a conditional clause.** The body declares **no scope block at all**, and what will be built lives inside one acceptance criterion's own conditional — while a sibling criterion asserts full coverage.

> - [ ] Reuse-first check performed and documented…
> - [ ] A pipeline-wide evidence store exists — **built net-new only if the reuse-first check finds no adequate existing trail**
> - [ ] The downstream indicator is upgraded from the single close-gate boolean to the full rate
> - [ ] The rate is computed **from that store** and emitted

Bullet 2 conditions the object of the build on bullet 1's outcome; bullets 3–4 assert full coverage regardless. Reuse-extension and net-new-ledger are entirely different surfaces, so until the first check runs, nobody can say what the last two criteria will be graded against.

**A caution on how to spot Shape 2.** The tell is that **no declared-scope block resolves in any form** — not at `###`, not at `##`, not as a bold-prose block. It is **not** a heading count. A tell keyed to "the body has no `###` headings" inverts on real bodies: it misses the genuine Shape-2 case, whose body carries an unrelated `###` heading, and it fires on a perfectly well-scoped body that happens to render its whole template at `##`. Heading level is an artifact of how a body was authored; look for the **block**, not the hashes.

`[SOURCE: a deferred capability card carrying no declared-scope block, whose acceptance criteria conditioned the build object on another criterion's outcome while asserting full coverage; the self-contradiction was detected only at acceptance review and required an operator override record to close.]`

### Your two exits as an author

When either shape describes your draft, take one of exactly two exits — and take it **before** build scope locks, which is the whole reason the check fires at triage:

1. **Narrow the assertion** to what the declared scope determinately produces. State the rest as a separate item, or as a non-graded Notes commitment.
2. **Resolve the scope** — name the branch you actually mean instead of the disjunction, or add the missing producing surface to the declared scope.

Neither exit is "widen the wording until it is vague enough to cover both". A well-formed ticket is determinate in **both** operands, not ambiguous in a way that lets any build satisfy it.

**What this rule is NOT.** It is not a demand for line-level scope — a **file-level directional pointer** is and remains the required form (§2 T4, §5). It does not fire on broad *intent*; it fires on an asserted, acceptance-graded **outcome** the declared scope cannot produce. And a scope field that is *wholly* the sanctioned deferral marker with correspondingly deferred criteria is deliberately open scope, not a defect.

---

## 5. What Goes at Stage 5 vs. Intake

The decision table below operationalizes the WHAT/HOW boundary. Items in the **Stage 5 Solutioning** column are design decisions; items in the **Intake** column are problem-statement decisions. A well-formed intake ticket populates only the right column (or marks left-column items as `[ASSUMPTION – CONFIRM]` deferred to Stage 5).

| Stage 5 Solutioning (HOW) | Intake (WHAT) |
|---|---|
| Algorithm choice (e.g., "binary search vs. linear scan") | Problem statement (e.g., "lookup must complete in O(log n) for 10k+ entries") |
| Data structure selection (e.g., "use a Trie") | Constraints (e.g., "must support prefix queries; insert/lookup ratio is 1:100") |
| File-internal implementation (e.g., "rename function to `parseHeader`, extract to module") | Directional file pointer (e.g., "`auth.ts` — header-resolution path; precise scope identified in Planning") |
| Pattern naming (e.g., "use the visitor pattern", "apply the strategy pattern") | Observable outcome (e.g., "traversal must support 3 caller types without re-parsing") |
| Pseudocode (`for x in xs: if x.foo: emit(x)`) | Acceptance criteria (e.g., "verify only active items are rendered; method: snapshot test of the dashboard with 10 items, 3 active") |
| Temporal-window metrics committed in Acceptance Criteria (e.g., "30-day rescore", "60-day adoption") | Merge-time-verifiable Acceptance Criteria + post-close Monitoring commitment in Notes (e.g., "Monitoring: re-run query N at merge+30d; target band 20-50%") |
| A named instrument committed inside an Acceptance Criterion (e.g., "`<specific-test-file>` executed by a CI job") | Observable-intent Acceptance Criteria naming the artifact whose state is asserted (e.g., "predicate: the generator is exercised by a CI job; method: a CI-run test imports it and asserts on its output") |

### How Triage uses this table

When a ticket fails T2 (determinate design committed prematurely), Triage's self-repair guidance cites this table:

> "The Proposed Change prescribes a HOW (specifically: \[item from Stage 5 column\]). At intake we commit WHAT. Either (a) re-author the ticket using the corresponding WHAT framing, or (b) mark the design as `[ASSUMPTION – CONFIRM]` and explicitly defer to Stage 5 Solutioning. See `release/references/how-to/intake-style-guide.md` §5."

`[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §D Over-definition mitigations]` `[SOURCE: release/references/pipeline/stage-05-solutioning.md §5 Phase 0 Activation criteria]`

---

## 5b. Split-Template Trigger (B6)

The platform deliberately does NOT split `improvement.yml` into per-type templates speculatively. The governance-intake split (`improvement.yml` + `observation.yml` + `bug.yml` + `adr.yml`) is evidence-backed: each of those templates responds to a documented quality failure pattern in the corpus. The pack-projected methodology-kind forms (`epic.yml`, `story.yml`) are capability-driven arms per the scope-of-trigger note below, registered in the §1b routing table at their shipping release.

**Trigger to add a new type-specific template:**

> When a category label accumulates **≥15 tickets** with **type-mean weighted total < 3.0** AND **type-D3 < 2.5**, re-audit the corpus for that type and consider adding a type-specific template.

**Rationale:** Don't add `enhancement.yml`, `documentation.yml`, `refactor.yml`, or `research.yml` now — the n<10 per-type sample is too small for the failure pattern to be evidence-backed rather than theoretically-predicted. Revisit when volume grows. This is an anti-overengineering guardrail.

**Scope of this trigger:** this gate governs quality-failure-driven splits — adding a type-specific template because a category's intake quality is failing against the thresholds above. It does not bar a capability-driven intake arm that ships through the governed release process (issue → bundle → approved plan): such an arm is evidence-backed by its own release decision rather than by the re-audit thresholds. Either way, the arm registers in the §1b routing table on landing — registration is routing bookkeeping, not a speculative split.

**How to apply the trigger:**

1. Periodic intake-quality re-audits (cadence: 6-month default; see `<OPERATOR_INSTANCE_ANALYSIS_PATH>/` for prior audits) compute type-mean weighted total and type-D3 per category label.
2. If any type meets BOTH thresholds (≥15 tickets AND type-mean < 3.0 AND type-D3 < 2.5), open an intake-quality follow-up issue proposing a type-specific template.
3. The new template's design follows the same evidence pattern: identify the failure mode, design fields that mitigate it, validate against re-scoring of historical tickets in that category.

`[SOURCE: <OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/recommendations.md §B6 Triggers to split further templates later]`

---

## 5c. The Assumption-Handoff Convention (owner + closure-path)

The 5-test rule lets an intake author defer a decision with `[ASSUMPTION – CONFIRM]` (T2 design deferral, T4 file-pointer deferral, T5 risk deferral). A deferred assumption is **not** a resolved assumption — and intake never resolves it. Every `[ASSUMPTION – CONFIRM]` an intake ticket carries must name **who owns the resolution** and **how it gets closed**, so that the assumption travels downstream as a *trackable, owned item* rather than a silent open question that a later stage discovers (or worse, never discovers) for itself.

This is the general form of a convention the platform already ships for one class. The bug/root-cause class proves the shape: when a defect lands with an unknown cause, [`core/disciplines/root-cause-analysis.md`](../../../core/disciplines/root-cause-analysis.md) §2 has intake emit, verbatim, `[ASSUMPTION – CONFIRM] <unknown cause> — owner: root-cause — to close: RCA per core/disciplines/root-cause-analysis.md` and **stop** — it does not root-cause inline (the boundary is [ADR-016](../../../core/ADRs/ADR-016-intake-front-door-architectural-boundary.md) §3). That `owner:` / `to close:` form is the convention; this section generalizes it from the single bug/unknown-cause class to **every** intake assumption, of any test class. It does not invent a parallel mechanism — it lifts the proven one to the full intake-assumption surface.

### The convention (one rule)

> **Every intake `[ASSUMPTION – CONFIRM]` carries a named owning later-stage and an explicit closure path, in the form:**
>
> ```
> [ASSUMPTION – CONFIRM] <the assumption stated as a confirmable claim> — owner: <named later stage / discipline> — to close: <the explicit action + where it happens>
> ```
>
> Intake records the assumption; it does **not** auto-resolve it. The named owner is the stage that has the context intake lacks; the closure path is the concrete action that turns the assumption into a confirmed fact (and, by doing so, closes the item).

| Field | What it states | Drawn from |
|---|---|---|
| `[ASSUMPTION – CONFIRM] <claim>` | The assumption phrased as a single confirmable claim — not a vague worry. | The same marker the 5-test rule already uses (T2 / T4 / T5). |
| `owner:` | The **named** later stage or discipline that resolves it (e.g., `Stage 5 Solutioning`, `Planning`, `root-cause`, `Stage 2 Triage`). Never "later" or "someone" — a named owner is the load-bearing word. | Generalized from `owner: root-cause` in `root-cause-analysis.md` §2. |
| `to close:` | The **explicit** action that confirms the claim and where it happens (e.g., "design selected at Stage 5 per the §5 decision table", "file path confirmed in Planning", "RCA per core/disciplines/root-cause-analysis.md"). | Generalized from `to close: RCA per …` in `root-cause-analysis.md` §2. |

**Owner by test class** (the routing already implied by §2 Failure routing, now made explicit as an owner):

| Assumption arises from | Typical `owner:` | Typical `to close:` |
|---|---|---|
| **T2** — design deferred (HOW not committed at intake) | `Stage 5 Solutioning` | "design selected at Stage 5 per the §5 WHAT/HOW table; alternatives assessed for blast radius" |
| **T4** — file pointer deferred (`TBD — identified in Planning`) | `Planning` | "affected file(s) confirmed in Planning before Engineering picks the issue up" |
| **T5** — cross-issue / concurrent-work risk | `Stage 2 Triage` | "conflict checked at Triage dependency-validation; native `blocked-by` mirrored if real" |
| **bug / unknown cause** (the proven class) | `root-cause` | "RCA per core/disciplines/root-cause-analysis.md" |

### Intake never auto-resolves; Triage validates closure ownership

Two halves of the same contract:

- **Intake side (the output contract).** An intake ticket that *guesses* the answer to its own assumption — committing a design under a T2 deferral, naming a file it has not confirmed, declaring a risk "won't happen" — has auto-resolved an assumption it has no authority to resolve. The correct output is the owned, deferred form above. This is the intake-output contract: assumptions leave intake **open and owned**, never silently closed. (Mirrors the `intake-desk` hand-off discipline: emit the owner, stop, do not perform the downstream work inline.)
- **Triage side (the validation).** Triage validates closure ownership before bundling: every `[ASSUMPTION – CONFIRM]` on an approved-queue ticket must carry a resolvable `owner:` and a concrete `to close:`. An assumption with no owner, or a `to close:` that is not a checkable action, is a Triage self-repair finding — Triage routes it back for an owner, exactly as it routes a T2 over-definition back for WHAT framing. This is the `owner: root-cause` triage check (["Triage of a root-cause-owned assumption" — the define/triage stage routes the assumption to its owner for closure before bundling](../../../core/disciplines/root-cause-analysis.md)) generalized: triage checks **every** assumption has an owner, not only the root-cause-owned one. Triage validates the *ownership*; it does not itself confirm the assumption (that is the named owner's job at its stage). See [`release/references/pipeline/stage-02-triage.md`](../pipeline/stage-02-triage.md) §6 Outputs / §7 Stage-Transition Gate (the issue-body state Triage validates before an issue may sit in the Approved queue).

### Worked intake-output example

A `[Process]`-type intake ticket whose Proposed Change cannot yet name the enforcement file, with a deferred design — both assumptions carried as trackable, owned items:

> **### Proposed Change**
> Add a closure-ownership check so every intake assumption names its resolver. Enforcement surface: `[ASSUMPTION – CONFIRM] the check lives in the Triage gate vs. a deploy-check — owner: Stage 5 Solutioning — to close: mechanism selected at Stage 5 per the §5 WHAT/HOW table (gate-step vs. CI check assessed for blast radius)`. Affected file: `[ASSUMPTION – CONFIRM] exact gate file TBD — owner: Planning — to close: file path confirmed in Planning before Engineering picks the issue up`.
>
> **### Acceptance Criteria**
> - Every approved-queue ticket's `[ASSUMPTION – CONFIRM]` entries carry a named `owner:` and a checkable `to close:` (verify by reading the ticket body).
>
> **### Risks**
> - `[ASSUMPTION – CONFIRM] may overlap the existing G1 enforcement set if both land same release — owner: Stage 2 Triage — to close: dependency conflict checked at Triage; native blocked-by mirrored if real.`

Each assumption is a *trackable, owned item*: a reviewer reading the body sees who resolves it and what action closes it, and Triage can validate that ownership before the ticket bundles — without asking the author a single question. Intake committed the WHAT and the ownership; the named owners commit the HOW at their stages.

`[SOURCE: core/disciplines/root-cause-analysis.md §2 — the proven owner:/to-close: hand-off form, generalized here from the bug/unknown-cause class to the full intake-assumption surface]`

---

## 6. Cross-References

This guide is the doctrine. The following docs are the enforcement surfaces:

| Doc | Section | Relationship |
|---|---|---|
| `release/references/pipeline/stage-01-intake.md` | §5 (Path A two-tier intake) | Path A applies the tier-selection test (Proposal vs. Observation tier) — the 5-test rule informs the tier choice. |
| `release/references/pipeline/stage-05-solutioning.md` | §5 (Phase 0 Activation Gate) | Stage 5 activates when intake correctly defers HOW per T2; this guide tells authors when to defer. |
| `release/references/pipeline/stage-02-triage.md` | §6 (Outputs), §7 (Stage-Transition Gate) | Triage validates closure ownership before bundling — every `[ASSUMPTION – CONFIRM]` must carry a resolvable `owner:` / `to close:` per §5c; an unowned assumption is a Triage self-repair finding. |
| `core/disciplines/root-cause-analysis.md` | §2 (trigger), §4 (invocation points) | The proven `owner:` / `to close:` form (for the bug/unknown-cause class) that §5c generalizes to every intake assumption. |
| `release/references/standards/solutioning-output-template.md` | § 3.5 (The Solutioning Pre-Read) | Intake-authority mirror pair: this guide's §5c governs intake-*emitted* `[ASSUMPTION – CONFIRM]` assumptions (directional, owned downstream); § 3.5 governs Stage-5-*emitted* advisory pre-reads (non-binding, the issue body stays the contract). Same theme, different emitting stage — the two complete the WHAT-vs-HOW-vs-advisory authority boundary. |
| `release/references/pipeline/stage-02-triage.md` | § Scope-Altitude Determination (A4.7 / `SA-G1`) | Enforcement surface for §4c. A **stage-local, advisory, non-gate-blocking** criterion — not a `gate-criteria-spec.md` registry criterion, outside the Layer-2 judgment aggregate, riding the existing A6 `feasibility flags` field. It carries the predicate (Limb A ∨ Limb B), the SA1–SA3 bar, the operand-resolution rules and the closed N1–N7 guard list; §4c carries the authoring doctrine and cites them. |
| `release/references/pipeline/stage-02-triage.md` + `core/deploy/deploy.sh` Check 71 | § Section-Anchor Resolution (A4.8) | Surfacing surfaces for §2d. Both are **advisory, report-only, never gate-blocking**: numeric section anchors in open issue bodies are resolved against the cited file's actual headings, and an anchor that resolves to nothing is surfaced as a `feasibility flags` bullet (triage) or an `ADVISORY:` line (deploy). The predicate declares the citation classes it does not model, with measured counts, in `core/deploy/tools/check-issue-body-anchors.sh`'s header — a clean run means nothing was found in the modelled classes, not that every anchor resolves. |
| `core/schemas/gate-criteria-spec.md` | G1-04 (Proposed Change specificity), G1-05 (AC verifiability — branch (i) per-bullet quality, branch (ii) capability-class usability-AC coverage per §4b) | Triage gates that operationalize T2 (G1-04) and T3 (G1-05); G1-05b branch (ii) is the enforcement surface for §4b, whose § Capability-Class Usability-AC Requirement block carries the predicate, the exempt classes, and the conformance tests. |
| `core/schemas/gate-criteria-spec.md` + `core/deploy/deploy.sh` Check 22 | G1-01 (title informativeness floor) | Enforcement surfaces for the §7 title rubric. The gate enforces the **syntactic floor only** (no bracket prefix + substance floor); the §7 rubric carries the semantic informativeness bar (judgment, not gate-enforced). |
| `<OPERATOR_INSTANCE_ANALYSIS_PATH>/intake-quality-review-2026-04-19/best-practices-rubric.md` | D4 (Intake/Design Boundary) | Rubric dimension that scores intake/design boundary respect; T2 maps to D4. |
| `.github/ISSUE_TEMPLATE/improvement.yml` | Description, Proposed Change fields | Field descriptions point authors to this guide for the 5-test rule. |
| `.github/ISSUE_TEMPLATE/observation.yml` | All fields | Lightweight intake form used when T3/T4/T5 fail and the author cannot fix at authoring time. |
| `.github/ISSUE_TEMPLATE/bug.yml` | description + header comment | Bug-type intake arm. The chooser description carries the one-line discriminator only; the type→template rule lives at §1b (single-source per `core/standards/duplicate-source-discipline.md`). |
| `.github/ISSUE_TEMPLATE/epic.yml` | description + header comments | Pack-projected Epic kind form (methodology-resolved intake arm). Chooser description carries the one-line discriminator; the type→template rule lives at §1b; `labels:` stamps `type:epic` structurally. |
| `.github/ISSUE_TEMPLATE/story.yml` | description + header comments | Pack-projected Story kind form (methodology-resolved intake arm). Chooser description carries the one-line discriminator; the type→template rule lives at §1b; `labels:` stamps `type:story` structurally. |
| `CLAUDE.md` | Continuous Improvement § auto-logging rule (per the Continuous Improvement Protocol) | Quality-floor subclause directs agents to apply the tier-selection test before authoring. |
| `core/governance/OPERATIONS.md` | § Continuous Improvement Protocol Path A | Path A intake-template selection is preceded by Anti-pattern D check: temporal-window AC content routes to Notes (or stays in AC with merge-time rewrite). |

`[CONTEXT: core/governance/OPERATIONS.md Continuous Improvement Protocol]` — operational expansion of the auto-logging rule with the tier-selection test workflow.

## 7. Title Summary-Informativeness

A work-item title is a **self-contained, outcome-shaped summary** — understandable from the issue list alone, with no label click and no body read needed. **Type lives on the label; the title spends its whole space on the change.** Titles carry no bracketed `[...]:` type/category prefix.

This section is the doctrine. The **enforcement** surfaces (gate G1-01 + `deploy.sh` Check 22) enforce only the **syntactic floor** below; the **quality bar** (the heuristics and worked examples that follow) is judgment — `intake-desk` elicits to it, and a reviewer reads it; neither the gate nor any LLM scores it. A title can clear the floor and still be a poor summary (e.g. "Update the gate" passes the floor yet names no object — the floor cannot catch that; this rubric can).

### Structural floor (the mechanical minimum — what the gate enforces)

| # | Floor rule | Rationale |
|---|---|---|
| F1 | **No bracketed type/category prefix.** A title must not lead with `[...]:`. | The label carries type; a prefix duplicates it and burns title space. |
| F2 | **Names an object + a change.** ≥ 2 words; not a bare area-slug (`intake-desk`, `repo-platform`). | A bare noun names *where*, not *what changed*. |
| F3 | **Sentence case, ≤ ~70 chars, no trailing period.** | Reads cleanly in the GitHub issue-list column. (The gate enforces a minimum length as a backstop; the upper bound and casing are author discipline.) |

### Quality heuristics (the bar — `intake-desk` elicits to these; NOT gate-enforced)

| Heuristic | Bad | Good |
|---|---|---|
| Lead with the change, not the area | `intake-desk titles` | `Drop the redundant type prefix from issue titles` |
| Name the object **and** the action | `Fix title format` | `Make issue titles human-readable; remove the category prefix` |
| Disambiguate from neighbours — if two open issues could share it, it is too vague | `Update the gate` | `Repurpose G1-01 into a title-informativeness floor` |
| The dropped prefix **buys back** space — spend it on specificity | `deploy fails` | `Fix deploy.sh unbound-variable crash on empty package set` |

### Worked good/bad set (type-agnostic — not tied to live issue numbers)

- ✓ `Make work-item titles human-informative — drop the redundant type prefix`
- ✓ `Cache the issue-list query in the bundle parser to cut Stage-3 runtime`
- ✗ `[Enhancement]: titles` (bracket prefix + bare area — fails F1 + F2)
- ✗ `fix-titles` (slug, one token — fails F2)
- ✗ `Update the gate` (clears the floor, but names no object — fails the *disambiguation* heuristic, which the gate cannot enforce; this is exactly where author/`intake-desk` judgment is the only control)

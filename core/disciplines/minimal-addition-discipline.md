---
title: Minimal-Addition Discipline
purpose: The default discipline for an agent ADDING content to governance or reference
  corpus — add the minimum that carries the meaning, in service of *simplicity*. The umbrella
  authoring discipline of which duplication is one facet; it composes with the durability
  ladder (which sets the floor) rather than restating it.
type: discipline
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
applies_to: any agent authoring or editing durable governance / reference corpus —
  core/, release/, .claude/rules/, workspace-root governance files; Stage 5/6 spokes
parallel_to:
  - reference-durability-standard.md   # sets the floor (carry a brief durable summary inline); this discipline sets the ceiling
  - duplicate-source-discipline.md     # the duplication facet (register-or-remove); cross-references UP to here
  - reconcile-dont-annotate.md         # the edit-time sibling (minimal-change scoping on an edit)
source: codification of an operator-resolved discipline (origin issue in the References block);
  names the platform value "simplicity" the discipline serves (the build-philosophy Simplicity
  coverage cell it fills); Reversibility MODERATE / Confidence HIGH
---

<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# Minimal-Addition Discipline

When an agent adds content to governance or reference corpus, the **default is to add the least content that carries the meaning**. The platform value this serves is **simplicity** — the smallest addition that conveys the meaning, and no more. This is a *default posture* an agent adopts whenever it authors or edits durable corpus, not an invokable procedure a stage hands off to.

This discipline is the **umbrella**; **duplication is one facet** of it. The detail of the duplication facet — the register-or-remove rule and its enforcement layer — is owned by `duplicate-source-discipline.md`, which cross-references UP to this discipline. The discipline composes with — does **not** restate — the reference-durability standard's durability ladder: that ladder sets the floor (carry a brief durable summary rather than a fragile link), this discipline sets the ceiling (carry no more than the meaning needs). The two bound the same act from opposite sides (Section 3).

The corpus already *invokes* "simplicity" as a first-class value (the build-philosophy engineering-values set; the design-principle register's DP-4) but codified no authoring-time discipline that serves it — the build-philosophy Simplicity coverage cell was a named GAP. This doc fills that GAP: it is the authoring-time discipline the value pointed at but lacked.

---

## Section 1 — The discipline (the rule), stated unconditionally

When adding content to governance or reference corpus:

- **Add the minimum that carries the meaning.** The smallest addition that conveys the meaning is the target; anything beyond it is over-addition.
- **Prefer a reference (by durable name/role) over a detailed restatement.** When the meaning already lives in a governed home, name that home by its durable role and carry a brief durable summary — do not restate the source in detail.
- **Prefer an inline comment over a new section.** A clarification that a sentence or a comment carries does not warrant a new heading; reach for the lightest structure that holds the meaning.
- **Omit examples that will go stale unless load-bearing for comprehension.** An example earns its place only when the rule is not understood without it AND it will not rot on a rename, renumber, or count change.

The value these serve is **simplicity**. This rule is stated unconditionally and carries no version-cutover clause — the discipline doc is itself durable corpus and governs its own authoring.

---

## Section 2 — The minimal-addition test (binary; agent-applicable)

Apply this to ANY proposed addition to governance/reference corpus. Answer the
four questions IN ORDER; the first question that resolves returns the disposition.
The disposition is one of: **ADD** (the addition as written) · **TRIM** (cut to the
minimum durable summary + a role-named reference, then ADD that) · **OMIT** (do not
add it).

1. **Does the meaning already live in a governed home reachable by a durable
   reference?**  If YES → does the addition RESTATE that source in detail (more than
   a brief durable summary)?
     - Detailed restatement → **TRIM** to a brief durable summary + a role-named
       reference (minimal-addition ceiling; see the floor/ceiling boundary).
     - Bare reference with NO inline meaning → **TRIM** the other way: ADD the brief
       durable summary so the prose reads on its own (durability floor).
     - Already a brief durable summary + role-named reference → **ADD** (it is the
       target band).
   If NO governed home exists → go to 2.

2. **Is this content duplicated from another file in the corpus?** (the duplication
   facet — `duplicate-source-discipline.md` owns the detail.)  If YES → **TRIM**:
   consolidate to one canonical source + cross-reference, or register the mirror.
   If NO → go to 3.

3. **Is this an example?**  If YES → is it LOAD-BEARING for comprehension (the rule
   is not understood without it) AND durable (it will not go stale on a rename /
   renumber / count change)?
     - Load-bearing AND durable → **ADD**.
     - Otherwise (decorative `e.g.`, illustrative-but-rottable, stale-prone) → **OMIT**.
   If NOT an example → go to 4.

4. **Default question — does the addition carry meaning the surrounding text does
   not already carry?**
     - YES, and it is the least text that carries that meaning → **ADD**.
     - YES, but it is more than the meaning needs → **TRIM** to the minimum.
     - NO (it restates, decorates, or pads what is already said) → **OMIT**.

**Disposition is binary at each step** (the addition either passes as-written → ADD,
or it does not → TRIM/OMIT). "Minimal" is narrowed to these four checkable questions;
a residual judgment remains at Q3 (load-bearing?) and Q4 (least text?) — name the
judgment, do not pretend the test is fully mechanical.

---

## Section 3 — The floor/ceiling boundary (reconciliation with the durability ladder)

**The durability floor and the minimal-addition ceiling bound the same act from opposite sides; they do not contradict.**

- **Floor (set by the reference-durability standard's durability ladder):** when you need another doc's meaning, carry a **brief durable summary inline** rather than a fragile cross-file link that rots on a rename or renumber. A bare link with no inline meaning fails the floor.
- **Ceiling (set by this discipline):** carry **no more than the meaning needs** — a *detailed restatement* that duplicates a source is over-addition. A verbose restatement fails the ceiling.
- **The allowed band between them:** **the minimum durable summary that carries the meaning, plus a role-named reference.** That single form satisfies both standards at once.

So "prefer a reference over a detailed restatement" is scoped to *detailed restatement that duplicates a source* — it does **not** override the durability requirement to inline a brief durable summary. When the two seem to conflict, you are reading the floor against the ceiling; the band between is the target.

Cross-reference the durability ladder by its role — the reference-durability standard's **durability ladder** (rung 1, the prose rule stated unconditionally inline; rung 2, the self-describing boundary that names a concept or file by its content) — not by a fragile path-only reference. The `allow-link` marker in this file's frontmatter covers any role-named link to that standard.

---

## Section 4 — The three named-behavior clauses

Each of the three recurring over-addition behaviors this discipline governs has a dedicated clause.

- **Clause 4a — Stale-prone examples.** Omit an example unless it is load-bearing for comprehension AND durable. A decorative or illustrative `e.g.` that will rot on a rename / renumber / count change is over-addition — cut it. (Q3 of the test.) This is the behavior the card's evidence flagged: net-new runbook prose carrying inline `e.g.` worked examples beyond the rule, which become drift candidates the moment the surrounding content shifts.
- **Clause 4b — Restatement-over-reference.** When the meaning already lives in a governed home, prefer a brief durable summary + a role-named reference over a detailed restatement of that source. A detailed restatement duplicates the source and rots independently of it. (Q1 of the test; the ceiling of the floor/ceiling boundary in Section 3.)
- **Clause 4c — Duplicated references.** Do not copy the same reference or content into multiple files. This is the duplication facet — consolidate to one canonical source + cross-reference, or register the mirror, per `duplicate-source-discipline.md` (register-or-remove). That doc owns the detail; this clause names duplication as one facet of minimal addition. (Q2 of the test.)

---

## Section 5 — Composition with sibling disciplines

This discipline composes with — does not duplicate — the disciplines that govern the neighbouring surfaces. Each direction is named, and the neighbours are cited by role-name rather than by restating their rule bodies.

- **`reference-durability-standard.md`** — **COMPLEMENTS.** It sets the floor (carry a brief durable summary inline rather than a fragile link); this discipline sets the ceiling (carry no more than the meaning needs). The band between is the target — see Section 3. The two are orthogonal and both run; neither subsumes the other.
- **`duplicate-source-discipline.md`** — **SUBSUMES-AS-FACET.** Duplication is one facet of minimal addition. That doc owns the register-or-remove detail and its byte-identity enforcement layer; it cross-references UP to this discipline as the umbrella it instantiates.
- **`reconcile-dont-annotate.md`** / **`surgical-edits`** (the build-philosophy Simplicity row) — **ALIGNED.** Minimal-change scoping on an edit is the edit-time cousin of minimal addition: surgical scoping bounds *how much* you change an artifact you are already touching, minimal addition bounds *how much* you add. Both serve simplicity.

---

## Section 6 — Deferred enforcement

Authoring-time enforcement — a check that flags over-addition at the moment content enters the corpus — is a **candidate downstream child, deferred**. The mechanism is TBD and relates to the candidate Governance Hygiene & Drift CI enforcement epic. No check ships in this deliverable, and no placeholder file is created: an enforcement surface with no behaviour behind it would be theater. Until such a check ships, this discipline is enforced by the same judgment-and-review posture as the other authoring disciplines — the minimal-addition test (Section 2) is the agent-applicable gate, and review-class skills apply it when auditing net-new corpus content.

---

## See also

- [`reference-durability-standard.md`](../standards/reference-durability-standard.md) — the durability ladder this discipline complements; it sets the floor (brief durable summary inline), this sets the ceiling (no detailed restatement).
- [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md) — the duplication facet (register-or-remove); it cross-references UP to this discipline as its umbrella.
- [`reconcile-dont-annotate.md`](reconcile-dont-annotate.md) — the edit-time sibling; minimal-change scoping is the edit-time cousin of minimal addition.
- [`build-philosophy.md`](build-philosophy.md) — the Simplicity engineering value this discipline serves; this doc is the authoring-time enforcer the Simplicity coverage cell named as a GAP.

## References

- #751 — origin issue: *Codify a "minimal-addition" authoring discipline for governance & reference corpus* (the operator-resolved discipline body, named value "simplicity", and floor/ceiling reconciliation codified above).

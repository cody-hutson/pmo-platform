<!-- Eval fixture — demonstrative scenario for gate-definitions.md §4.3. Every pack value below is read from a shipped manifest; none is invented. No real stakeholder names. -->
# Fixture: resolved-kit criteria at a gate

A demonstrative scenario for the resolved-kit admission and reporting rule in [`../../references/gate-definitions.md`](../../references/gate-definitions.md) §4.3. It exercises one case per branch arm of that section's three-outcome table, so a run that handles only the populated arm fails visibly here rather than silently in production.

**This fixture is read, not executed, and that is deliberate.** `delivery-engine` is agent-executed: the kit read is an agent read of the resolved manifest, never a call into the shipped pack reader. On an inline-table array that reader returns fragments *and reports a clean parse*, so a mechanical implementation would evaluate shredded input while appearing to have worked. §4.3 states the prohibition for the read path; it binds this fixture identically — do not turn these cases into a parser harness.

**Pack values are quoted from `core/packs/{scrum,kanban}/pack.toml` as shipped.** Check ids, statements, `level` and `automatable` values below resolve in those manifests. If a pack changes, this fixture's expected sets change with it — that is the intended coupling, and it is why no count here is restated as a rule in §4.3.

---

## Case A — resolved and populated: the gate FAILs on a real kit criterion

**Input.** Archetype `Scrum` (`delivery_approach` resolves the `scrum` pack). Kind `story` (the item carries `type:story`, the label projection of `kind_id = "story"`). The work item is a story whose `acceptance_criteria` is **empty**. Gate **LG-4** (Sprint DoR) at `T(6→7)`; kit key `criteria.readiness`.

**Expected criterion set.** The six `[LG-4-EX-k]` exit criteria from `gate-definitions.md` §2, **plus** the admitted subset of the kind's `criteria.readiness` block. Admission is the §4.3 predicate applied per check:

| Check id | `level` | `automatable` | Admitted? | Why |
|---|---|---|---|---|
| `dor-story-valuable` | L1 | `true` | **admitted** | `automatable = true` — the predicate's first disjunct |
| `dor-story-testable` | L1 | `true` | **admitted** | `automatable = true` |
| `dor-story-estimable` | L1 | `true` | **admitted** | `automatable = true` |
| `dor-story-independent` | L3 | `false` | not admitted | not `automatable`; the record dispositions it `NOT-EVALUATED` (unmeasured), so no disjunct is satisfied |
| `dor-story-negotiable` | L3 | `false` | not admitted | same |
| `dor-story-small` | L3 | `false` | not admitted | same |

**Expected verdict: FAIL**, citing `dor-story-testable` by id — *"acceptance_criteria is present with at least one entry."* That is a real criterion from a shipped pack failing on a real predicate, not a constructed one. Per §4.1 the transition is **BLOCKED**, and the rejection names the first violated criterion by ID.

**Expected report block** (beside the verdict, never inside it):

```
Resolved-kit criteria -- kind: story . key: criteria.readiness
  checks read 6 / admitted 3 / reported 3
  reported, not admitted:
    dor-story-independent   disposition: NOT-EVALUATED (record: check not measured)
    dor-story-negotiable    disposition: NOT-EVALUATED (record: check not measured)
    dor-story-small         disposition: NOT-EVALUATED (record: check not measured)
```

**Caveat strings emitted: zero.** A resolved kit emits no unresolved caveat.

**What a wrong run looks like here.** Admitting the three non-admitted checks. Each is unmeasured, so admitting one makes the aggregate's behaviour unknown rather than benign — and if it later measures `advisory-only`, admission makes the aggregate either structurally incapable of ALLOWED or nondeterministic depending on which disjunct fired. Reporting them is the correct handling; evaluating them is the defect.

---

## Case B — resolved and reasoned-empty: the emptiness is the content

**Input.** Archetype `Kanban` (`delivery_approach` resolves the `kanban` pack). Kind `card` (`kind_id = "card"`). A well-formed card. A **gate**-class transition; kit key `criteria.gate`.

**Precondition, stated inline so it can be re-derived without running anything.** The reasoned-empty arm fires when **both** hold on the resolved block: its array is **present and empty** (`checks = []`), **and** the block carries a non-empty **block-level** `source`. That conjunction is the discriminator declared at `core/schemas/work-item-type-schema.md` §1.2.1 *Content provenance* — the `source` on a present-and-empty declaration is what distinguishes a reasoned empty bar from an unauthored one. Emptiness alone never decides it, and the `source` alone never does either.

Read the block directly to confirm both limbs. Do **not** infer emptiness from a reader's item count: the kanban `criteria.gate` line carries a trailing TOML comment containing brace characters, which defeats a naive brace-matching item count on this exact block — a live instance of why §4.3 prohibits the mechanical read.

**Expected criterion set.** The six `[LG-4-EX-k]` only. `criteria.gate.checks = []` contributes **nothing** — no criterion is added, and **no template item substitutes for the absent ones**.

**Expected verdict.** Whatever the `[LG-4-EX-k]` block renders on this card. The kit contributes no FAIL and no PASS.

**Expected report block:**

```
Resolved-kit criteria -- kind: card . key: criteria.gate
  checks read 0 / admitted 0 / reported 0 -- present and empty, carrying a block-level source
  practice basis, from the block's own source:
    Kanban Method (Anderson 2010) -- reasoned empty set. The Method prescribes that a
    WIP limit exist and leaves its number to the service running the board, so this gate
    ships declared and unbound rather than carrying a cap no body of practice could
    ground. "The emptiness is the practice basis, not a placeholder."
```

**Caveat strings emitted: zero.** This is a resolved kit. No `NOT-EVALUATED` line is emitted — the block was read successfully and says something definite.

**What a wrong run looks like here, and why this is the case that matters.** A run implementing `if not checks: fall back to the generic checklist` substitutes this doc's criteria for a kind whose methodology **deliberately prescribes no per-item transition gate**. It produces a plausible verdict, emits no warning, and is wrong — a silent default wearing a sensible costume. A run implementing `if not checks: emit NOT-EVALUATED` is also wrong, in the opposite direction: it reports an unreadable input where the input was read and was deliberate. **A fixture written from Case A alone exercises neither failure.**

---

## Case C — unresolved: the gate is unchanged and says so once

**Input.** No `delivery_approach` resolves, so no pack resolves. Kind `story` is asserted by the caller. Gate **LG-4** at `T(6→7)`; kit key `criteria.readiness`. (The same arm is taken when the pack resolves but no `type:<kind_id>` does — §4.3 forbids inferring the kind from context.)

**Expected criterion set.** The six `[LG-4-EX-k]` only — **byte-identical to the pre-§4.3 behaviour.** No kit criterion joins, and none is substituted.

**Expected verdict.** Whatever the `[LG-4-EX-k]` block renders — **identical to what the gate rendered before §4.3 existed.** This is the property that makes §4.3 additive: the unresolved path's verdict does not move.

**Expected report block — exactly one line, never one per check:**

```
NOT-EVALUATED -- kind: story . key: criteria.readiness . checks read 0 / admitted 0 / reported 0 . cause: no kit resolved (delivery_approach unresolved)
```

**Caveat strings emitted: one.** This is the only case of the three that emits one, and the literal token `NOT-EVALUATED` is the greppable discriminator between this arm and either resolved arm.

**What a wrong run looks like here.** Emitting one `NOT-EVALUATED` line per unevaluated check, which is the vacuity `gate-criteria-spec.md` § Step 0 forbids in terms (*"never once per issue"*); or omitting the denominator, which makes a consumer that reports on every kind indistinguishable from one that works; or rendering `NOT-EVALUATED` in a `PASS` / `CONDITIONAL PASS` / `FAIL` position, which would breach the §4.1 naming guard that closes the verdict set at three values.

---

## Cross-case assertions

- **The caveat-string count is `zero / zero / one` across Cases A / B / C.** Both resolved arms are silent on the unresolved vocabulary; only the unresolved arm emits it. A run that emits a caveat on Case A or Case B has conflated "not admitted" with "not readable".
- **Every case emits a report with a denominator**, including the two whose admitted subset is empty. An empty admitted subset is a reported state, never a silent pass.
- **No case renders a fourth verdict value.** Every verdict above is one of `PASS` / `CONDITIONAL PASS` / `FAIL`; `NOT-EVALUATED` appears only in a report block beside the verdict.

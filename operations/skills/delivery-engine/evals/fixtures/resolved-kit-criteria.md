<!-- Eval fixture — demonstrative scenario for gate-definitions.md §4.3. Every pack value below is read from a shipped manifest; none is invented. No real stakeholder names. -->
# Fixture: resolved-kit criteria at a gate

A demonstrative scenario for the resolved-kit admission and reporting rule in [`../../references/gate-definitions.md`](../../references/gate-definitions.md) §4.3. It exercises every branch arm of that section's three-outcome table, so a run that handles only the populated arm fails visibly here rather than silently in production. The populated arm carries **two** cases because it has two materially different outcomes — an admitted subset that is non-empty (Case A) and one that is empty (Case D) — and a run can handle the first while getting the second wrong.

Each case also names the kit key it reads, and the three keys between them cover §4.3's whole **read scope**: Cases A and C read `criteria.readiness`, Case B reads `criteria.gate` at a gate-class transition, and Case D reads `criteria.done`. A fixture that exercised only the readiness key would leave the other two arms of the read scope undemonstrated.

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

**Input.** Archetype `Scrum` (`delivery_approach` resolves the `scrum` pack). Kind `story` (the item carries `type:story`, the label projection of `kind_id = "story"`). A well-formed story. A **gate-class** transition — the agent is asked to move the story along the Axis-1 edge `ready -> in-progress`, the same edge kanban's declared gate guards. Per §4.3's **read scope**, a gate-class transition binds kit key `criteria.gate`.

**Precondition, stated inline so it can be re-derived without running anything.** The reasoned-empty arm fires when **both** hold on the resolved block: its array is **present and empty** (`checks = []`), **and** the block carries a non-empty **block-level** `source`. That conjunction is the discriminator declared at `core/schemas/work-item-type-schema.md` §1.2.1 *Content provenance* — the `source` on a present-and-empty declaration is what distinguishes a reasoned empty bar from an unauthored one. Emptiness alone never decides it, and the `source` alone never does either.

Read the block directly to confirm both limbs. Do **not** infer emptiness from a reader's item count, and do **not** infer it from the key: **the same `criteria.gate` key is reasoned-empty in the `scrum` pack and populated in the `kanban` pack**, whose card carries a gate check whose `condition = { … }` value is a nested inline table — braces inside braces, on the same line as the check. A reader that decides emptiness by matching braces, or by generalizing from one pack's block to another's, gets this case wrong in one direction or the other. Emptiness is a property of the resolved block, never of the key — which is a live instance of why §4.3 prohibits the mechanical read.

**Expected criterion set.** Whatever `[LG-N-EX-k]` block the gate this edge sits at declares, and nothing else. `criteria.gate.checks = []` contributes **nothing** — no criterion is added, and **no template item substitutes for the absent ones**. (§4.2 forbids fabricating a transition coordinate the stage→gate seam does not assert, so this case names the Axis-1 edge and leaves the `LG-N` to the seam.)

**Expected verdict.** Whatever that `[LG-N-EX-k]` block renders on this story. The kit contributes no FAIL and no PASS.

**Expected report block:**

```
Resolved-kit criteria -- kind: story . key: criteria.gate
  checks read 0 / admitted 0 / reported 0 -- present and empty, carrying a block-level source
  practice basis, from the block's own source:
    Scrum Guide 2020 -- reasoned empty set. Scrum prescribes no per-item transition
    gate for a story; the framework's only prescribed controls are the Sprint boundary
    and the Definition of Done, and criteria.done plus the project lifecycle already
    carry both. The inherited Axis-1 states contain none a Scrum-sourced gate could
    guard, so a check authored here would be an invention wearing a citation.
    "The emptiness is the practice basis, not a placeholder."
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

## Case D — resolved and populated, admitted subset empty: the report carries its denominator

**Input.** Archetype `Kanban` (`delivery_approach` resolves the `kanban` pack). Kind `card` (`kind_id = "card"`). A card the service considers finished. Gate **LG-5** (Dev Complete / DoD) at `T(8→9)`; per §4.3's read scope a *done* transition binds kit key `criteria.done`.

**This is the populated arm, not a fourth arm.** The block resolves and carries checks; what is empty is the **admitted subset**, not the block. §4.3 states the consequence in terms — *"a block whose admitted subset is empty still emits the report with its denominator"*, and *"an archetype whose declared checks are all non-admitted contributes nothing to either gate while still reporting on both."* Cases A and B demonstrate neither: Case A admits three of six, and Case B's block is empty before admission is ever reached. This case is where that clause is exercised.

**Expected criterion set.** The `[LG-5-EX-k]` exit criteria from `gate-definitions.md` §2, **plus** the admitted subset of the kind's `criteria.done` block — which is empty. Admission is the §4.3 predicate applied to each of the block's three declared checks:

| Check id | `level` | `automatable` | Admitted? | Why |
|---|---|---|---|---|
| `kanban-dod-exit-policy-satisfied` | **L2** | `false` | not admitted | not `automatable`; the record carries it as a CONTROL member whose arm resolved nothing, so no disjunct is satisfied |
| `kanban-dod-delivery-point-reached` | L3 | `false` | not admitted | not `automatable`; unmeasured in the record, so no disjunct is satisfied |
| `kanban-dod-flow-record-complete` | L3 | `false` | not admitted | same |

**The first row is the one to read twice.** It is **L2**, not L3, and it is still not admitted — because the predicate keys on the `automatable` flag, never on the level. The evaluability record names this check explicitly as one of exactly two where the `level = L3` set and the `automatable = false` set diverge, and warns that arithmetic subtracting the L3 count from the total to get the machine-evaluable count is wrong by two. A reader who generalizes "L1/L2 admitted, L3 reported" from Case A's table alone will admit this check and be wrong on shipped content.

**Expected verdict.** Whatever the `[LG-5-EX-k]` block renders on this card — **the kit moves it neither way.** The kit contributes no FAIL and no PASS, exactly as in Case B, but for a different reason: there the block was empty, here every declared check was read and none was admitted.

**Expected report block** (beside the verdict, never inside it):

```
Resolved-kit criteria -- kind: card . key: criteria.done
  checks read 3 / admitted 0 / reported 3
  reported, not admitted:
    kanban-dod-exit-policy-satisfied    disposition: NOT-EVALUATED (record: check not measured)
    kanban-dod-delivery-point-reached   disposition: NOT-EVALUATED (record: check not measured)
    kanban-dod-flow-record-complete     disposition: NOT-EVALUATED (record: check not measured)
```

**The denominator is the whole point of this case.** `checks read 3 / admitted 0 / reported 3` and `checks read 0 / admitted 0 / reported 0` are different states that a report without a denominator renders identically — the first says three declared checks were read and none qualified, the second says there was nothing to read. A consumer that emits `admitted 0` with no denominator is indistinguishable from one that never resolved the kit at all.

**Caveat strings emitted: zero.** This is a resolved kit that was read successfully. No `NOT-EVALUATED` **report line** is emitted — and note that the token does appear above as a **disposition value carried verbatim from the record**, which §4.3 distinguishes in terms: same word, two subjects. The report token marks an unreadable input; the disposition value marks a check the record has not measured. This case emits the second and not the first.

**What a wrong run looks like here.** Admitting `kanban-dod-exit-policy-satisfied` because it is L2 — the level/flag conflation above. Or emitting `NOT-EVALUATED` as the report token because the admitted subset came out empty, which reports an unreadable input where three checks were read and reported. Or dropping the report entirely on the grounds that it changes no verdict, which is the silent pass §4.3 forbids: **an empty admitted subset is a reported state, never a silent pass.**

---

## Cross-case assertions

- **The caveat-string count is `zero / zero / one / zero` across Cases A / B / C / D.** Every resolved arm is silent on the unresolved vocabulary; only the unresolved arm emits it. A run that emits a caveat on Case A, B or D has conflated "not admitted" with "not readable" — and Case D is the one where that conflation is most tempting, because its admitted subset is empty for a reason that has nothing to do with readability.
- **Every case emits a report with a denominator**, including the three whose admitted subset is empty. An empty admitted subset is a reported state, never a silent pass.
- **`admitted 0` means two different things across these cases, and only the denominator separates them.** Cases B and C report `checks read 0`; Case D reports `checks read 3`. A report that omits the denominator collapses "nothing was declared" into "nothing qualified", which are opposite findings about the kit.
- **Admission never keys on `level`.** Case A's admitted rows are L1 and its reported rows are L3, which is a correlation and not the rule; Case D's first reported row is **L2**. The predicate reads the `automatable` flag, and a run that infers a level threshold from Case A alone fails Case D.
- **No case renders a fourth verdict value.** Every verdict above is one of `PASS` / `CONDITIONAL PASS` / `FAIL`; `NOT-EVALUATED` appears only in a report block beside the verdict — as a report token in Case C, and as a record-carried disposition value in Cases A and D.

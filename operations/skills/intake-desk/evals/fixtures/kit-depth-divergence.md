<!-- Eval fixture — demonstrative scenario for elicitation-loop.md § Phase 3. Every pack value below is read from a shipped manifest; none is invented. No real stakeholder names. -->
# Fixture: two kits, one request, materially different elicitation

A demonstrative scenario for the depth-resolution rule in [`../../references/elicitation-loop.md`](../../references/elicitation-loop.md) § Phase 3 — specifically its three-outcome table (`resolved` / `reasoned-empty` / `unresolved`) and the instruction to evaluate that table **per realizer instance, not once per kind**. One request is carried through three resolutions, so a run that handles only the populated arm fails visibly here rather than silently at the desk.

**The request is held constant. Only the resolved kit moves.** That is the whole construction: if the elicitation differs across the cases below, the difference is attributable to the kit and to nothing else. A fixture that varied the request as well would demonstrate nothing about the kit.

**This fixture is read, not executed, and that is deliberate.** `intake-desk` is agent-executed: the kit read is an agent read of the resolved manifest, never a call into the shipped pack reader. § Phase 3 states in terms that the reader's **default** mode fragments the `checks[]` inline-table arrays — returning split `statement` values while reporting a clean parse — so a fragment-shaped depth bar would read as a successful one. That prohibition binds this fixture identically: do not turn these cases into a parser harness.

**Pack values are quoted from `core/packs/{scrum,kanban}/pack.toml` as shipped.** Field names, check ids, `level`, `automatable` and block-level `source` values below resolve in those manifests. If a pack changes, this fixture's expected asks change with it — that is the intended coupling, and it is why no count here is restated as a rule in § Phase 3.

---

## The request (identical in all three cases)

> "The status panel shows everything. People only ever want the active items, and they keep asking us to filter it by hand."

Phase 1 lands it at **change-the-business**, Work-Item altitude — a leaf, so the container-altitude existing-owner scan does not fire and Phase 2 advances directly on the altitude gate. What Phase 2 resolves next is the only thing that varies below.

---

## Case A — Scrum resolves: the kind declares its own field set and its own bar

**Input.** `delivery_approach` resolves the `scrum` pack. Phase 2 derives the kind registry and lands the request on kind `story` (`kind_id = "story"`).

**Expected field ask.** The inherited Work-Item core, **plus** the kind's five `fields.kind_specific` declarations — the ask's *expected structure* and *required content*, the authoring standard's first two dimensions:

| Field | `required` | `cardinality` | What the ask is for |
|---|---|---|---|
| `as_a` | ✅ | one | role — the who of the story |
| `i_want` | ✅ | one | goal — the capability sought |
| `so_that` | ✅ | one | benefit — the value rationale |
| `acceptance_criteria` | ✅ | many | the conditions of satisfaction (the done test) |
| `story_points` | ⚪ | one | relative-size estimate |

Four are required and one is optional; the ask distinguishes them rather than demanding all five.

**Expected depth read.** The kind's `criteria.readiness` block resolves **populated**, carrying six checks. Which of the six bound *depth* rather than structure or content is decided by the ordered procedure in `core/standards/work-item-authoring-standard.md` § 2.2, applied per entry and stopping at the first yes — this fixture does not re-adjudicate that split, it records what the block declares:

| Check id | `level` | `automatable` |
|---|---|---|
| `dor-story-valuable` | L1 | `true` |
| `dor-story-testable` | L1 | `true` |
| `dor-story-estimable` | L1 | `true` |
| `dor-story-independent` | L3 | `false` |
| `dor-story-negotiable` | L3 | `false` |
| `dor-story-small` | L3 | `false` |

**The same kind also lands in `reasoned-empty`, and that is the ordinary case rather than an edge one.** `story`'s `criteria.gate` array is **present and empty** and carries a block-level `source` — *"Scrum prescribes no per-item transition gate for a story."* Per § Phase 3's *evaluate per realizer instance* instruction, a run that stops at `resolved` because the kind matched it on `criteria.readiness` suppresses that statement. Both outcomes fire on this one kind.

**Caveat strings emitted: zero.** A resolved kit emits no unresolved caveat.

**What a wrong run looks like here.** Asking for all five kind-specific fields as though all were required. Or consulting the neutral altitude floor *in addition to* the resolved declarations — § Phase 3 says the floor "is **not** consulted" when a kit resolves, so a run that blends the two is asking to a bar no methodology declares.

---

## Case B — Kanban resolves: the emptiness is the guidance, and the ask shrinks

**Input.** The identical request. `delivery_approach` resolves the `kanban` pack. Phase 2 lands it on kind `card` (`kind_id = "card"`).

**Expected field ask.** The inherited Work-Item core, and **nothing beyond it**. `card`'s `fields.kind_specific` array is **present and empty**, and the `fields` block carries a block-level `source`. That conjunction — empty array **plus** block-level `source` — is the reasoned-empty discriminator declared at `core/schemas/work-item-type-schema.md` § 1.2.1 *Content provenance*. Emptiness alone never decides it, and the `source` alone never does either.

**The basis is stated to the user rather than silently skipped**, from the block's own `source`:

```
Kanban Method (Anderson 2010) -- reasoned empty set, and the ground is a mandate
boundary rather than a silence. Foundational principle 1, Start with what you do
now, makes Kanban a change method laid over an existing process: it mandates no
required card field list, so no field set is owed here. ... What the Method
prescribes per card is policy-shaped, and core practice 4 puts that content in
the readiness and done criteria this kind populates, not in fields.
```

**Expected depth read.** `card`'s `criteria.readiness` block resolves **populated**, carrying two checks — and neither is `automatable`:

| Check id | `level` | `automatable` |
|---|---|---|
| `kanban-dor-pull-policy-explicit` | L2 | `false` |
| `kanban-dor-commitment-point-reached` | L3 | `false` |

Both are policy-shaped and service-scoped, so the ask they produce is about *this service's written pull policy and commitment point* — not about a role-goal-benefit frame, which this kind never names.

**Caveat strings emitted: zero.** This is a resolved kit. The `fields` block was read successfully and says something definite.

**What a wrong run looks like here, and why this is the case that matters.** A run implementing `if not kind_specific: fall back to the neutral floor` substitutes the invariant field emphasis for a kind whose methodology **deliberately mandates no card field list**. It produces a plausible interview, emits no warning, and is wrong — a silent default wearing a sensible costume. A run implementing `if not kind_specific: emit the unresolved caveat` is also wrong, in the opposite direction: it reports an unreadable input where the input was read and was deliberate. **A fixture written from Case A alone exercises neither failure.**

---

## Case C — no kit resolves: the neutral floor, and the caveat that says so once

**Input.** The identical request. Neither `operational_methodology` nor `delivery_approach` resolves at any rung of the 5-rung cascade, so no pack resolves and no archetype is defaulted to.

**Expected field ask.** The methodology-neutral invariant registry's field set for the type at this altitude, derived per the field-derivation contract in `../../references/type-map.md`. No kind-specific set joins, because no kind resolved.

**Expected depth read.** **Both halves of the documented fallback, not the field set alone** — the neutral registry **and** its altitude floor, which is § Phase 3's three altitude bullets. The request sits at the story/stakeholder altitude, so the operative bullet is the middle one: intake-ready = acceptance criteria + value + WHAT-framed proposed change; over-defined = the item commits an implementation mechanism at intake.

**Expected caveat — exactly one line, never one per unresolved field:**

```
[platform-config: methodology unresolved; using the neutral intake registry
and its altitude floor for depth]
```

**Caveat strings emitted: one.** This is the only case of the three that emits one, and it is the greppable discriminator between this arm and either resolved arm.

**What a wrong run looks like here.** Silently defaulting to an archetype — § Phase 2 step 6 forbids it in terms (*"Unresolved is a caveat, not a default"*). Or emitting the registry without its floor, which drops the depth half of a two-half fallback and leaves the ask unbounded. Or emitting one caveat per field, which buries the single fact the operator needs.

---

## Cross-case assertions

- **The material divergence, side by side.** The request is held constant and the resolved kit varies; each row is a dimension of the ask:

  | | Case A — `scrum`/`story` | Case B — `kanban`/`card` | Case C — no kit |
  |---|---|---|---|
  | kind-specific fields asked | 5 | 0 | none (neutral registry) |
  | `criteria.readiness` checks read | 6 | 2 | 0 — no kit to read |
  | depth source | the kind's own declarations | the kind's own declarations | the three altitude bullets |
  | reasoned-empty statement carried | `criteria.gate` | `fields` | none |
  | caveat strings emitted | 0 | 0 | 1 |

  No two columns are the same in any row but one, and the row they share — depth source, for A and B — is shared only in name: the declarations differ entirely. **A run that produces the same ask in Cases A and B has not read the kit.**
- **The caveat-string count is `zero / zero / one` across Cases A / B / C.** Both resolved arms are silent on the unresolved vocabulary; only the unresolved arm emits it. A run that emits a caveat on Case B has conflated *"the kind declares nothing here"* with *"nothing could be read"* — which is the conflation this fixture exists to catch, because Case B is where it is most tempting.
- **`0` means two different things across these cases, and only the reason separates them.** Case B asks zero kind-specific fields because the resolved kind declares an empty set **on purpose, with its basis stated**; Case C asks none because no kind resolved at all. A run that renders those identically has collapsed a deliberate practice boundary into a configuration failure.
- **A kind can be `resolved` and `reasoned-empty` at the same time.** Case A is: its `criteria.readiness` is populated and its `criteria.gate` is a reasoned empty set. The three-outcome table is not a first-match ladder over kinds — a run that stops at the first row it matches suppresses every reasoned-empty statement the kind declares.
- **Nothing here changes when to stop.** The clarity gate and the 5-test are the exit condition in all three cases. This fixture varies **what is asked**, never **when to stop asking**.

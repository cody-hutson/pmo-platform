# Mixed-Release Solutioning Routing Protocol

> **Source:** Sub-slice 1 — Stage 5 Solutioning support.
> **Related:** blast-radius CLI (schema v1).

## 1. What this protocol is

This protocol defines **per-issue routing through Stage 5 Solutioning within a single release** ("mixed-routing"), distinguishing it from the all-or-nothing default in which all issues in a release either go through Solutioning or all skip it. The activation criteria for Stage 5 itself (new file, skill logic, structural design decisions, multiple valid approaches, cross-cutting 3+ governance files, blast radius uncertainty) are defined in [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) §5 Phase 0; this protocol layers a release-level routing decision **on top of** those criteria — answering "when criteria fire for some issues but not others in the same release, what happens?"

## 2. Current Mode

**Mixed-routing is DOCUMENTED but DISABLED.** Default routing remains all-or-nothing per release. No release activates mixed-routing without explicit operator declaration at Stage 4 Phase B AND prerequisite-control evidence per §9 Mixed-Routing Audit Trail.

This protocol exists as forward-state specification. Activation in any release is a Stage 4 release-plan decision; the release shipping this protocol explicitly applies all-or-nothing for its own 16 issues. A future release may activate mixed-routing if and only if the activation gate in §7 is satisfied.

## 3. Default rule: all-or-nothing per release

**Rule:** If any issue in a release triggers Stage 5 activation criteria, every issue in the release routes through Stage 5 (Path A per [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) Boundary Stage 5 → Stage 6). If no issue triggers criteria, every issue skips Stage 5 (Path B). Per-issue mixing is not permitted under the default rule.

**Source:** [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) §5 Phase 0 Activation Gate — "All-or-nothing per release." Also [`release/governance/release-process.md`](../../governance/release-process.md) Stage 5 entry "Activation" line.

**Rationale:**
- **Operational simplicity.** A release plan declares one routing posture; Stage 5 spokes and Stage 6 Engineering apply uniform spec-depth expectations.
- **Deterministic Stage 6 spec-depth interpretation.** Engineering A1 reads release-level posture, not per-issue routing — fewer ambiguity surfaces (cf. [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) Validation Rule 1: "Ambiguity = HOLD").
- **Conservative on ambiguity.** When the criteria fire for some issues, the default escalates the whole release to Solutioning rather than risking missed design analysis on an unrouted issue.

[SOURCE] [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) §5 Phase 0; [`release/governance/release-process.md`](../../governance/release-process.md) Stage 5.

## 4. Mixed-routing exception path (forward-state)

**Definition:** Mixed-routing is a release-level routing posture in which Stage 4 release-planner classifies each issue in the release with a `DESIGN` or `SKIP` token (per §5) and routes them individually — `DESIGN`-tokened issues receive Stage 5 sub-tasks (Path A); `SKIP`-tokened issues bypass Stage 5 and Engineering receives Planning-level specs (Path B).

This exception path is **documented for future use and not active in any release** until activated per the activation gate in §7. It exists to address the operational pressure documented in Stage 4 release plans where all-or-nothing forces near-trivial issues through Solutioning solely because the release also contains a single design-heavy issue. Mixed-routing reduces process overhead in such releases — but only when the prerequisite controls in §6 are met.

[CONTEXT] The operational pressure motivating this exception path is documented in a Stage 4 release plan §R10 (a release in which 8 of 16 issues were classified near-trivial yet routed through Stage 5 per all-or-nothing).

## 5. Issue classification scheme: DESIGN / SKIP

Under mixed-routing, the Stage 4 Applicability Matrix S5 column carries one of two tokens per issue:

- **`DESIGN`** — the issue routes through Stage 5 Solutioning. Equivalent to Path A per [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) Boundary Stage 5 → Stage 6: a Stage 5 sub-task is created, ADR drafting is eligible, and Solutioning-level specs are delivered to Stage 6 Engineering.
- **`SKIP`** — the issue bypasses Stage 5 Solutioning. Equivalent to Path B per the same boundary contract: no Stage 5 sub-task is created, Engineering receives Planning-level specs directly from the release plan, and a skip rationale is documented in §9 Mixed-Routing Audit Trail.

Both `DESIGN` and `SKIP` tokens preserve the existing Path A / Path B contract in [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md); they do not introduce a new boundary. The vocabulary makes the per-issue routing decision visible in the release plan rather than implicit in Stage 5 sub-task presence/absence.

## 6. Prerequisite controls (C1, C2, C3)

Mixed-routing activates only when all three controls return PASS. Any control returning FAIL or operator-overridden AMBIGUOUS causes the release to fall back to all-or-nothing.

### C1 — Dependency isolation

**Mechanism:** Stage 4 release-planner invokes [`engineering/tools/blast-radius.sh`](../../tools/blast-radius.sh) (per [`blast-radius-protocol.md`](blast-radius-protocol.md)) at A4 on every `DESIGN`-candidate issue's affected files. Verifies, using schema v1 `first_order` and `second_order` arrays (depth=2), that the intersection of the union(`first_order` ∪ `second_order`) for `DESIGN`-candidate files and the union(`first_order` ∪ `second_order`) for `SKIP`-candidate files is empty.

**Outcomes:**
- **PASS** = empty intersection across both depths.
- **FAIL** = any first-order or second-order edge crossing the DESIGN/SKIP boundary.
- **AMBIGUOUS** = edge classified as cosmetic-only per [`blast-radius-protocol.md`](blast-radius-protocol.md) impact classification — operator decides PASS or FAIL.

**Status today:** mechanism has shipped; operational use deferred to the first release that activates mixed-routing.

### C2 — Engineering dual-input handling

**Mechanism:** Engineering A1 already routes per-issue spec depth via Stage 5 sub-task presence/absence using [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) Boundary Stage 5 → Stage 6 (Path A / Path B). The contract supports per-issue routing within a release as a structural property of the boundary.

**Outcomes:**
- **PASS by reference** — structurally satisfied today.
- **FAIL** — only if a future migration breaks per-issue spec-depth routing at the boundary; protocol amendment required before mixed-routing can activate.

**Status today:** structurally satisfied; operationally unvalidated under within-release Path A/B coexistence. The control exists to capture future regressions that could break per-issue handling.

### C3 — Release plan classification format

**Mechanism:** Stage 4 Applicability Matrix S5 column carries `DESIGN` or `SKIP` per issue (not ✅ / ❌) under mixed-routing. The release plan includes a §Mixed-Routing Audit Trail section (per §9) documenting C1 evidence (blast-radius CLI invocation + JSON output reference) and skip rationale per `SKIP`-classified issue.

**Outcomes:**
- **PASS** = both the DESIGN/SKIP S5 column and the §Mixed-Routing Audit Trail are present.
- **FAIL** = either is missing.

**Status today:** backward-compatible additive; no existing release plan needs retroactive edit (see §10).

## 7. Activation gate

A release activates mixed-routing if and only if **all three** of the following hold:

1. **Operator declaration.** The operator explicitly declares mixed-routing at Stage 4 Phase B (release-plan approval comment, e.g., "mixed-routing: enabled"). Silence defaults to all-or-nothing.
2. **Audit trail present.** The release plan documents §Mixed-Routing Audit Trail with C1 evidence per `SKIP`-classified issue and operator-declaration timestamp.
3. **All controls PASS.** C1, C2, and C3 all return PASS per §6.

If any control returns FAIL — or returns AMBIGUOUS and the operator does not override to PASS — the release falls back to all-or-nothing release-wide. Mixed-routing is not partially activated; the release either runs mixed-routing under PASS conditions or runs all-or-nothing.

## 8. Consumers

### Stage 4 release-planner — [`stage-04-planning.md`](../pipeline/stage-04-planning.md)

At A4 (contention / applicability analysis), the release-planner evaluates whether the release is a mixed-routing candidate (operator has declared intent at Phase B or release composition suggests evaluation). If a candidate, it invokes [`blast-radius.sh`](../../tools/blast-radius.sh) per C1, constructs the Applicability Matrix with `DESIGN` / `SKIP` tokens in the S5 column, and writes §Mixed-Routing Audit Trail per §9. Output interpretation of blast-radius results follows [`blast-radius-protocol.md`](blast-radius-protocol.md). If the operator has not declared mixed-routing intent, the planner applies all-or-nothing without invoking C1.

### Stage 5 spokes — [`stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md)

Under mixed-routing, only `DESIGN`-tokened issues receive Stage 5 sub-tasks. Per-spoke behavior is unchanged from current; the spoke does not need to know whether the release is mixed-routing or all-or-nothing — it operates on the sub-task it receives. Under all-or-nothing (the default), spokes behave as today.

### Stage 6 Engineering — [`stage-06-engineering.md`](../pipeline/stage-06-engineering.md)

Engineering A1 routes per-issue spec depth via Stage 5 sub-task presence / absence using existing Path A / Path B handling per [`stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md). **No new Engineering behavior is required by this protocol.** Under mixed-routing, Engineering sees a release with some issues carrying Stage 5 sub-tasks (Path A) and others without (Path B) — the same routing already supported structurally.

## 9. Mixed-Routing Audit Trail format

When mixed-routing is activated, the release plan includes a top-level section structured as follows:

```
## Mixed-Routing Audit Trail — [release version]

Operator declaration: "mixed-routing: enabled" (Stage 4 Phase B, [timestamp]).

Per-issue routing:
- #[N] — DESIGN — [one-line rationale]
- #[N] — SKIP — rationale: [why classified SKIP]
  - C1 evidence: blast-radius.sh invocation [sub-task #N or commit SHA]; JSON output: [reference]
  - C1 outcome: PASS (empty intersection across DESIGN/SKIP affected files)
  - C2 outcome: PASS by reference (stage-io-contracts.md Path A/B)
  - C3 outcome: PASS (token present in S5 column)
[... repeat per SKIP issue ...]

Aggregate control outcome: C1 PASS / C2 PASS / C3 PASS.
```

The audit trail makes the activation evidence inspectable at release-close (Stage 13) and enables post-release retro of mixed-routing outcomes.

## 10. Backward compatibility

All-or-nothing release plans continue to use ✅ / ❌ in the Stage Applicability Matrix S5 column. Mixed-routing release plans use `DESIGN` / `SKIP` tokens in the same column. The two formats are mutually exclusive **per release** — a release plan declares its routing posture (implicitly by token choice) and uses one format throughout.

**No retroactive edits to prior release plans are needed.** The Stage 4 release-planner determines format per release-level routing decision; pre-existing plans (v10.x, v11.x through the release that ships this protocol) continue using ✅ / ❌ without modification.

## 11. See also

- [`pipeline/stage-05-solutioning.md`](../pipeline/stage-05-solutioning.md) §5 Phase 0 — activation criteria source for Stage 5 itself.
- [`pipeline/stage-04-planning.md`](../pipeline/stage-04-planning.md) — Stage Applicability Matrix consumer.
- [`schemas/stage-io-contracts.md`](../../../core/schemas/stage-io-contracts.md) Boundary Stage 5 → Stage 6 — Path A / Path B contract.
- [`protocols/blast-radius-protocol.md`](blast-radius-protocol.md) — C1 mechanism and output interpretation.
- [`release/governance/release-process.md`](../../governance/release-process.md) Stage 5 — operational rule consumer (cross-references this protocol).

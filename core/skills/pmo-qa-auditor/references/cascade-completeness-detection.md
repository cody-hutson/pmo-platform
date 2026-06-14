<!-- reference-durability: allow-link -->
# Cascade-Completeness Detection (G8) — PMO QA Auditor Reference

## Purpose

This file is the full specification for **G8 — Cascade-Completeness Verification**,
the Mode A gate `pmo-qa-auditor` fires when the output under audit is a **Stage 5 spec
carrying a `### Cascade-Sweep` block**. G8 is the **L5** layer of the cascade-completeness
defense-in-depth stack: the audit-time, across-the-changed-file-set detector that re-runs
each declared sweep and flags any OLD-value occurrence the swept-declaration table did not
enumerate. It is the automated complement to what Stage 7 design-time review (DT) catches
by hand, moved earlier (QA-time, post-Engineering, pre-DT) and made deterministic where the
check operates on a present block.

G8 is the structural analogue of **G7** (SKILL.md-scoped, two-phase, deterministic Phase 1):
both are file-type-conditional gates inside Mode A; G7 fires on a SKILL.md input, G8 fires on
a Stage 5 spec carrying a `### Cascade-Sweep` block. The SKILL.md G8 gate definition (Mode A
Process step 3) points here for the full tables.

**Authoritative cross-references:**
- `../../../release/references/pipeline/stage-05-solutioning.md` § 5.6 — the `### Cascade-Sweep`
  block schema, the T1/T2/T3 trigger conditions, and the value-scope derivative rule. G8 reads
  this block; it does not define a new schema.
- `../../specs/failure-mode-standard.md` — the `### Cascade-omission at count update — PROC`
  entry (the failure mode G8 detects) names G8 as the L5 detection surface.

---

## 1. The two-phase check

G8 mirrors G7's two-phase structure. **Phase 1 is deterministic and operates only on a
PRESENT block** (an absent block has no fields to grep). **Phase 2 is LLM-graded judgment** —
including the should-a-block-exist determination, which cannot be a regex check.

### Phase 1 — Structural (deterministic; operates on a PRESENT `### Cascade-Sweep` block)

| ID | Check | Method | Pass criterion |
|---|---|---|---|
| G8-02 | Each declared sweep command is reproducible | each `### Cascade-Sweep` "Sweep command(s)" entry is a runnable `grep -nE '<regex>' <file>` invocation with explicit file scope | All declared sweeps cite a runnable, file-scoped grep |
| G8-03 | **Re-run completeness — the load-bearing check.** Re-execute each declared sweep against the changed-file set on the release branch; every returned match has a corresponding `(file, OLD-value)` row in the swept-declaration table | for each `(file, OLD-value)` pair, the live `grep -nE '<regex>' <file>` match-set ⊆ swept-table row-set, where `<regex>` is **derived from the OLD-value string** (see § 2) | Zero un-enumerated matches → PASS; any match absent from the table → FAIL, with the exact `file:line` cited |
| G8-04 | Each table row carries a disposition (UPDATE / PRESERVE / N/A) + non-empty rationale; PRESERVE/N/A rationale is specific | per § 5.6 load-bearing test — disposition column non-empty; PRESERVE/N/A rows name a reason | All rows conformant |

### Phase 2 — Content (LLM-graded; judgment, not regex)

| ID | Check | Method | Pass criterion |
|---|---|---|---|
| G8-01 | **Should a `### Cascade-Sweep` block exist at all?** Re-derive the § 5.6 trigger determination: did a T1 (count) / T2 (enumeration) / T3 (threshold-narrative) change fire, or does a not-fired exclusion apply (NEW count with no prior value; value only in a fenced historical snapshot)? | LLM grader reads the spec's affected-files matrix + change intent against the § 5.6 trigger table and the "Trigger does NOT fire when…" exclusions | Block present when a trigger fired → PASS; **block absent when a trigger fired → FAIL** (negligent omission); block absent when no trigger / a not-fired exclusion applies → N/A, gate does not fire (correct omission) |
| G8-05 | PRESERVE/N/A dispositions are load-bearing, not gate-evasion | LLM grader reads each PRESERVE/N/A row + rationale; scores whether the preservation reason is load-bearing ("historical snapshot in a fenced archived block") vs. evasive ("looks intentional") 1–5 | Mean ≥ 4.0; individual ≥ 3 |
| G8-06 | **Cascade-scope completeness** — does the changed-file set carry the OLD value in a file **outside** the spec's declared affected-files matrix? | LLM grader compares the changed-file set vs. the spec's declared affected-files matrix for OLD-value carriers | A changed file carrying the OLD value but outside the declared matrix → CONDITIONAL with a **Tier 2 [SCOPE CHANGE]** finding |

> **Why G8-01 is Phase 2, not Phase 1.** The "should-a-block-exist" determination cannot be a
> deterministic regex check. In the FAIL case (block absent), there is **no field to grep** — the
> `triggers:` declaration exists only in the § 11 `cascade-sweep-block` *event payload*, which is
> emitted when a block is **present**, not when it is absent. And the "Trigger does NOT fire when…"
> exclusions (NEW-count, fenced-historical-snapshot) are irreducibly judgment-laden — a negligent
> omission and a legitimate omission are **indistinguishable at the structural layer**. So the
> determination belongs in Phase 2 (judgment), structurally parallel to G8-06. Phase 1 keeps only
> checks that operate on a present block (G8-02 reproducibility, G8-03 re-run completeness, G8-04
> disposition-present).

### Verdict (mirrors G7)

- All Phase 1 PASS + all Phase 2 thresholds met → **PASS**.
- All Phase 1 PASS + ≥1 Phase 2 below threshold → **CONDITIONAL PASS** (with findings).
- Any Phase 1 FAIL → **FAIL** (specific `file:line` / regex non-match cited).

The verdict vocabulary is the skill's existing **PASS / FAIL / CONDITIONAL PASS** — **no PARTIAL**
(the skill's Operating principle and its `PARTIAL verdict — PROC` failure mode forbid it).

---

## 2. Regex derivation (G8-03) — derived from the OLD-value string, NOT from a §5.6 column

**The § 5.6 `### Cascade-Sweep` table carries no per-row regex field.** Its columns are
`File | OLD value | Line | Context | Disposition | Rationale`; the actual grep regex lives only
in the free-text "Sweep command(s)" line. The "OLD value" column is a *value* (e.g., `20`), not a
*regex* (e.g., `\b20\b`). Reusing the §5.6 table is therefore "zero new schema **for the swept-set
membership test**" — it is NOT a claim that the table carries the regex.

**Resolution: G8-03 DERIVES its grep regex from the OLD-value string itself.** For each
`(file, OLD-value)` pair, G8 constructs the match pattern from the OLD-value as a regex-escaped
literal, expanded by the § 5.6 **value-scope derivative rule** (line 213): a value `20` sweeps
`20`, `(20)`, `20 custom`, and `twenty` if narratively used — NOT "all numbers anywhere in the
file." The author's free-text "Sweep command(s)" line is **advisory** (a human-readable record of
what was run); G8-03's join is computed from `(file, derived-regex)`, so it does not depend on
parsing an unconstrained free-text line.

This keeps G8-03 a genuine deterministic Phase-1 check **without expanding §5.6's schema**
(no new per-OLD-value regex column is added — that would be scope G8 does not own). If a future
release wants the regex first-class, that is a §5.6 forcing-function change, filed separately.

---

## 3. The swept-declaration read contract

G8 reads the **existing** §5.6 `### Cascade-Sweep` table as its swept-set. No new schema, no
frontmatter field, no sidecar `.swept` manifest. The contract:

| Property | Rule |
|---|---|
| **What "swept" means** | A `(file, OLD-value)` pair present as a table row = **swept**. A live `grep` match with no corresponding row = **un-swept** (G8-03 FAIL). |
| **Join key** | `(file, OLD-value)` is **load-bearing**; `line` is **advisory**. Engineering may shift line numbers between authoring and audit, so G8-03 matches on the `(file, OLD-value)` match-set ⊆ table-row-set — `line` is used for human-readable `file:line` citation, not as the join key. This tolerates benign line drift while still catching a genuinely un-enumerated occurrence. |
| **Disposition is honored, not re-litigated** | A row marked PRESERVE (e.g., historical snapshot) or N/A (coincidental match) is a **swept** row — G8 does **not** re-flag it (re-flagging would double-count L1's adjudication). G8-05 (Phase 2) grades only whether the PRESERVE/N/A rationale is load-bearing vs. evasive. |
| **Single source of truth** | The same table is L1's forcing-function self-check (design-review-checklist § 3.5), the §11 `cascade-sweep-block` pipeline-event payload, and now L5's swept-set. One artifact, three consumers — no second swept-declaration schema, no drift surface (duplicate-source-discipline). |

---

## 4. Failure-routing — matrix-relative (Tier 1 [ADJUST] vs Tier 2 [SCOPE CHANGE])

A G8-flagged occurrence routes by **whether the missed occurrence lies inside or outside the
spec's declared affected-files matrix**. G8 emits the finding with the routing tier in its
Evidence column; it does **not** self-resolve (consistent with the skill's "No rewriting"
guardrail — G8 flags + recommends, Engineering re-runs).

| G8 finding | Condition | Routing | Reversibility |
|---|---|---|---|
| Un-swept occurrence **inside** the declared affected-files matrix | The spec's own matrix named the file; an occurrence in it was not enumerated | **Tier 1 [ADJUST]** — Engineering refresh: update the missed occurrence + add the row to the sweep table | CHEAP (mechanical text fix on an already-in-scope file) |
| Un-swept occurrence in a changed file **outside** the declared matrix (the G8-06 signal) | The cascade reached a file the spec did not anticipate | **Tier 2 [SCOPE CHANGE]** — surface to hub Decision Briefing; cascade is broader than spec scope; operator decides add-to-release vs defer | MODERATE (re-scopes the spec; hub-coordinated per Collective Review Scope-Lock override process) |

This is the §5.6 cutover-tier vocabulary (Tier 1 [ADJUST] / Tier 2 [SCOPE CHANGE] per
`release-process.md` Inter-Stage Feedback Protocol).

---

## 5. L1–L5 composability (no double-counting)

G8 is the terminal **detection** layer of a five-layer stack. L1–L4 are authoring/review-time
**prevention** within the affected-files matrix (narrow file-scope, by §5.6 design); L5 is
audit-time **detection** across the whole changed-file set. L5 catches precisely the occurrence
L1's file-scope structurally excludes; it never re-flags a correctly-swept occurrence (a
swept-table row suppresses the G8-03 flag), so it adds coverage without re-counting L1–L4's wins.

| Layer | Surface | When it fires | What it covers | What it CANNOT see |
|---|---|---|---|---|
| **L1** | `stage-05-solutioning.md` § 5.6 (process-doc anchor) | Stage 5 authoring | Author enumerates OLD-value occurrences **within the affected-files matrix** | Occurrences in changed files **outside** the declared matrix; an author who omits the block |
| **L2** | `release-process.md` (rule-tier mirror) | Stage 5 / Collective Review | Rule-tier statement of the cascade rule | Same narrow file-scope as L1 |
| **L3** | `design-review-checklist.md` § 3.5 (forcing-function self-check) | Phase A4→A5 transition | Rejects an *incomplete* sweep block (5 structural shape checks) | Whether the block's enumeration **matches reality** on the branch — it checks shape, not grep-completeness |
| **L4** | `failure-mode-standard.md` `### Cascade-omission at count update — PROC` (catalog) | authoring-knowledge | Names the anti-pattern so authors avoid it | Nothing automated — a knowledge surface, not a detector |
| **L5 (this gate)** | `pmo-qa-auditor` G8 | **QA-time, post-Engineering** | **Re-runs the sweep against the changed-file set and flags any occurrence not in the swept table** — including changed files outside the matrix (→ Tier 2 [SCOPE CHANGE]) | (terminal detection layer) |

**Crisp, mechanism-distinct boundaries:**
- **L3 vs L5:** L3 inspects the **block's internal shape** at authoring (present? 5 fields? each
  disposition rationalized?) — a *self-consistency* check on the declaration. L5 inspects the
  **declaration against branch reality** at audit (does the enumeration match what grep returns?) —
  a *correspondence* check. L3 can PASS a block that is internally well-formed but factually
  incomplete; L5 is the layer that catches exactly that gap. Orthogonal properties of the same
  artifact at different pipeline times.
- **L1/L2 vs L5:** L1/L2 are prevention within the matrix (narrow file-scope, by §5.6 design). L5
  is detection across the changed-file set (the "whole-changed-file-set territory" §5.6 line 212
  hands off). L5 fires on the occurrence L1's file-scope structurally excludes.

---

## 6. Forward-note — invocation guarantee (CDF-1; out of #79 scope)

QA-time invocation gives **no unconditional invocation guarantee**: G8 fires only when
`pmo-qa-auditor` Mode A is actually pointed at a Stage 5 spec carrying a `### Cascade-Sweep`
block. If a release skips the QA pass on its specs, L5 silently does not run, and L1–L4
(authoring/review-time, narrow file-scope) are by design blind to the exact cross-file occurrence
L5 exists to catch. The §79 AC ("operational on at least one release post-deploy") is satisfied by
a single worked example and does not establish standing invocation.

A future deploy-time complement — a thin `deploy.sh` CI check (an L5′) that shells the same
derived-regex completeness logic at PR/merge time, **re-using G8's swept-declaration contract so
the two never diverge** — would close this coverage hole with a hard gate. The `git diff
--name-only "$diff_base"..HEAD` changed-files primitive already exists in `deploy.sh`, so this is a
clean later add. **It is filed as a forward-note only; it is NOT built here** (#79 ships the QA-time
G8 gate; the CI-enforced L5′ is a separate future-release candidate). A Stage-7/8 forcing-function
that *requires* G8 on any spec carrying a `### Cascade-Sweep` block is the alternative
invocation-guarantee path; same out-of-scope disposition.

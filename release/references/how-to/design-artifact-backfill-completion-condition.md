<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
# How-To — Design-Artifact Backfill Completion-Condition

> Standing how-to defining the **verifiable completion-condition** a design-artifact *backfill* task closes against — so "done" is a harness query result, not an assertion. It is release/build scaffolding for the [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) backfill work: reusable by the two surviving Wave-2 tasks of the `design-artifact-backfill` milestone — the declare-sweep (#3798) and the human-process build (#3441) — and by any future backfill of a flow type.

**Governing contract:** [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) **§ 9** (declaration — the embedded `<!-- design-artifact: … -->` marker + dedicated-file `depicts:`/`flow_class:` frontmatter) and **§ 12** (identification & detection — the per-flow-type conformance rules and the runnable enumeration harness). **Decision record:** [ADR-089](../../../core/ADRs/ADR-089-embedded-design-artifact-declaration-marker.md) (why an embedded artifact declares itself with a section-level marker). This how-to **consumes** those rules and does not restate them — the normative detail lives in the standard, and the standard wins on any divergence.

**Origin:** the #3614 spike (Deliverable **D2**). The spike found the six-flow-type build children's completion conditions were *unverifiable as written* — "every existing process has a design artifact" could neither pass nor fail while an embedded artifact was indistinguishable from prose (spike Findings 1–2). #3725 shipped the § 9 declaration + § 12 detection that turn the question into a query; this how-to codifies the corrected condition against that mechanism. It is the K1-boundary complement to the standard: the standard governs *what an artifact is and how it is declared/detected* (durable, version-agnostic); this how-to governs *when a backfill task is done* (release-scoped build scaffolding). Homing the condition here rather than in the K1 standard is the spike's D2 Template-Home recommendation (Risk R4 — do not conflate durable rendering rules with ephemeral build scaffolding).

---

## 1. When this fires

A **design-artifact backfill task** takes the existing platform processes of one or more § 2 flow types and ensures each is a *declared, detectable* design artifact. Two task-classes exist, and a single backfill task may be purely one or a mix:

| Task-class | Situation | Work | Surviving Wave-2 instance |
|---|---|---|---|
| **DECLARE** | The design artifact **already exists** as prose / tables / a fenced block in the § 2-cited parent, but is **undeclared** — invisible to the § 12 harness | Add the § 9 declaration (marker or frontmatter); author nothing | **#3798** — the consolidated TRIM-TO-DECLARE sweep (~27 artifacts across 5 flow types) |
| **BUILD** | No artifact exists for the flow type — the § 2 current-state column is genuinely empty | Author the artifact, declare it, and place it per the audience arm | **#3441** — the `human-process` FULL-BUILD (§ 2 cites zero; harness confirms zero) |

The MERGE-6→2 that produced exactly these two tasks was the operator's **D-FissionScope** decision (2026-07-24), taken on the spike's gap table (#3614, comment on #3786) — a query result, not an estimate. This how-to is what both tasks cite for their shared completion condition.

## 2. The completion-condition (both task-classes)

A backfill task is **COMPLETE** when, for each flow type in its scope, **every candidate process is accounted for by exactly one disposition below, and the disposition is verified by the § 12.2 harness plus the § 12.1 conformance rule for that flow type** — never asserted.

The candidate list is the flow type's § 2 `Current-state reference` column, **enumerated live at the task's Stage 5, not pre-fabricated** (§ 2's column is a human navigation aid, not the artifact census — the spike showed it under- and mis-counts; see § 6 below). For each candidate:

| Disposition | Precondition | Action | Verified by |
|---|---|---|---|
| **(b) exists-undeclared → DECLARE** | The artifact-bearing region already renders the flow type's tool (a table for the three table-rendered types; a fence/Mermaid for the rest) | Add the § 9 declaration: an embedded `<!-- design-artifact: flow-class=…; name=…; depicts=… -->` marker under the section heading, **or** `depicts:` + `flow_class:` frontmatter for a dedicated file | § 12.2 harness increments the type's count **and** the § 12.1 rule PASSES on the *declared region* |
| **(c) genuinely missing → BUILD** | Harness + grep confirm zero existing (§ 2 cites none) | Author the artifact, declare it (as above), and place it per § 3 storage + the audience arm (§ 4 below) | Same — the declared region PASSES the § 12.1 rule and the harness count for the type is now `> 0` |

Two whole-set conditions close the task on top of the per-candidate dispositions:

- **Harness gate:** the § 12.2 per-flow-type count is `> 0` for every flow type in scope (no type in scope may end at zero — a zero means an unmarked exists-undeclared artifact or an un-built missing one).
- **No orphaned artifacts:** § 9 bidirectional cross-reference and § 10 ownership are satisfied for every artifact touched, and the Stage 13 **G-CL6** refresh-gate (§ 8) is exercised for the set.

> **The load-bearing shift:** identification is **declaration-based, not rendering-based** (§ 12). A marker alone is *necessary but not sufficient* — the declared region must also **conform** to the type's § 12.1 rule. Marking a prose section that carries no table/fence/Mermaid does not make it an artifact; it makes it a failing declaration (see the § 5 fail example).

### 2.1 DECLARE-task specialization

For a pure DECLARE task (e.g. #3798), every candidate is disposition **(b)**: the completion condition reduces to "every enumerated existing artifact carries a § 9 declaration verified by the § 12.2 harness (per-flow-type count `> 0`), and each declared region PASSES its § 12.1 rule." A candidate that turns out **not** to render its type's tool at all is not silently marked — it is either (i) re-classified and dropped from the type, or (ii) escalated to a BUILD candidate, or (iii) recorded as a known rule-gap when the miss is the *rule's* (the decision-tree `triage-design-rereview.md` table-rendered-logic edge is the standing example: § 12.1 rule 7 is not table-aware, so that candidate is recorded as a rule-gap + a mechanism fast-follow, **not** forced to pass — see #3798's completion condition).

### 2.2 BUILD-task specialization

For a BUILD task (e.g. #3441), the candidate list is authored, not marked. Each artifact is **authored → declared → placed**, then verified exactly as (c) above. Placement follows the audience arm (§ 4). "Every existing process has an artifact" becomes testable because the built artifact is declared and the harness now returns it.

## 3. Verification method — run the § 12.2 harness

The verification is the enumeration harness canonical in [`design-artifact-standard.md` § 12.2](../../../core/standards/design-artifact-standard.md#-12-artifact-identification--detection). Reproduced here as the runnable verification step (the standard is authoritative if the two ever diverge):

```bash
# Dedicated artifacts (depicts: frontmatter — § 9)
grep -rl '^depicts:' core operations release

# Embedded artifacts (section-level marker — § 9)
grep -rn '<!-- design-artifact:' core operations release

# Per-flow-type count (dedicated + embedded, one row per type)
for t in architecture data-flow agent-process human-process concept-model skill-flow decision-tree; do
  d=$(grep -rlE "^flow_class:[[:space:]]+$t\b" core operations release --include='*.md' | wc -l)
  e=$(grep -rn "design-artifact:[^-]*flow-class=$t\b" core operations release --include='*.md' | wc -l)
  printf "%-16s dedicated=%s embedded=%s total=%s\n" "$t" "$d" "$e" "$((d+e))"
done
```

**How to read it for closure:**

1. Run the per-flow-type loop **before** and **after** the task. Every flow type in the task's scope must move from `total=0` (or its pre-task count) to `total > 0`, and the delta must equal the number of candidates the task disposed as (b)/(c).
2. For each new declaration, open the declared region and confirm it PASSES the § 12.1 rule for its `flow-class` (the region-scoped, table-aware conformance check — cite `file:line` + rule outcome, as the gap table did). The harness proves *declared*; the § 12.1 read proves *conforms*.
3. The three grep queries are deterministic (RUN 1 == RUN 2 over an unchanged tree), so the evidence is reproducible for the Stage 8 acceptance review and the release plan's Verification Evidence section.

## 4. Placement — the corrected § 2-embed-default location arm

Backfill artifacts follow § 3 storage + § 4 naming, under the location clause **as corrected pre-spike** on the six build children (#3437–#3442). Reference — do not re-derive — this corrected arm:

- **Embedded in the parent doc by default** (§ 2 / § 3): the artifact lives as a marker-declared section in its § 2-cited parent. This is the dominant existing pattern and the corrected default.
- **Dedicated `core/diagrams/<flow-type>-<name>.md`** *only* when the § 3 centralization-test is met (referenced from ≥ 3 parent docs).
- **Skill-owned `{core,operations,release}/skills/<skill>/diagrams/`** when the artifact is owned by a skill's behavior, not a cross-cutting concern.
- **Human-facing home `docs/`** (audience arm) when the artifact's reader is a **human operator** — the established user-facing documentation set (see [`docs/README.md`](../../../docs/README.md)) — rather than an agent-governance parent. The prior three arms all resolve to agent-governance surfaces; for a human-reader flow type (the `human-process` build), placing the explainer inside an agent instruction file would co-mingle audiences, so placement is **audience-determined, not only centralization-threshold-determined**.

**Correction provenance (why this arm reads the way it does):** the six children's AC originally defaulted to a dedicated diagram file; it was corrected **2026-07-23** to add § 2's embed-default arm (embedded-in-parent is the default; dedicated is the ≥ 3-parent exception), and **2026-07-24** to add the `docs/` audience arm. Those were instance-level completion-condition corrections applied directly to #3437–#3442 **pre-spike**; the gap enumeration and confirm-or-collapse decision remained the spike's deliverables. This how-to generalizes the corrected arm so every future backfill task inherits it rather than re-deriving (and re-mis-deriving) the default.

## 5. Worked pass / fail example

**PASS — a DECLARE candidate (data-flow, the decisive table-only case).** `core/schemas/stage-io-contracts.md` carries the boundary producer→consumer contract tables and **0 fenced blocks / 0 Mermaid / ~100 table rows**. Before the sweep the harness shows `data-flow … total=0` — a fence count is structurally blind to it. Add the § 9 marker on its own line under the contract-table heading (shown here with the flow-class value **bracketed** as `<data-flow>` — the § 9 grammar-placeholder idiom, `<one-of-7>` — so this illustrative how-to does **not** itself register in the § 12.2 count; a real declaration writes the bare enum `data-flow`):

```
<!-- design-artifact: flow-class=<data-flow>; name=stage-io-contracts; depicts=<the pipeline-stage docs whose I/O it maps> -->
```

After: the type's harness count increments (`data-flow … total` goes from 0 to 1), and the § 12.1 **rule 2** (table-aware: a markdown table with producer→consumer / schema / contract columns) PASSES on the marker-bounded region. Candidate disposed (b), verified — **complete**. This is the whole point of declaration-based identification: a 0-fence artifact that a rendering-count cannot see is unambiguously found and classified.

**FAIL — a marker without conformance.** A candidate is marked `flow-class=agent-process`, but its declared region is ordinary prose with **no `` ```mermaid `` fence and no fenced ASCII flow-block** (arrows `→` / `▼`). The harness increments (`agent-process … total` goes up), but § 12.1 **rule 3** FAILS on the region — a marker was added to something that does not render the agent-process tool. The task is **not** complete: the fix is either to author the missing flow-block (converting the candidate to a (c)/BUILD disposition) or to conclude the candidate was mis-identified and drop it from the type. A harness increment alone never closes a candidate — the § 12.1 read is the second, load-bearing check.

**FAIL that is recorded, not forced — the known rule-edge.** `triage-design-rereview.md` renders genuine decision logic as classification tables; § 12.1 **rule 7** (decision-tree) is not table-aware and does not conform on it. Per #3798's completion condition this is **recorded as a known § 12 rule-gap + a mechanism fast-follow logged**, not marked-to-pass and not authored-around inside this milestone. A completion condition that cannot be met by the current mechanism is surfaced as a rule-gap, never faked green.

## 6. What this how-to does NOT do (K1 boundary)

- It does **not** restate the § 9 marker grammar, the § 12.1 per-flow-type conformance rules, or the § 12.2 harness as *rules* — it cites them by section and reproduces the harness only as a runnable verification step, with the standard as SSOT. Any rule change lands in [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md), never here.
- It does **not** re-open the § 2 flow-type taxonomy, the § 3 storage decision, or the § 6 tool selection.
- It does **not** author or move any artifact itself — the DECLARE sweep (#3798) and the human-process BUILD (#3441) do that work; this file is the completion contract they close against.
- It carries **no version-scoped counts as durable rules** — the "~27 artifacts / 5 flow types" figures live in the task bodies and the gap table (a point-in-time query), not here; this how-to states the *condition*, the tasks carry the *census*.

## Related References

- [`design-artifact-standard.md`](../../../core/standards/design-artifact-standard.md) — the K1 standard this how-to serves; § 9 (declaration) and § 12 (identification & detection) are the governing contract.
- [ADR-089](../../../core/ADRs/ADR-089-embedded-design-artifact-declaration-marker.md) — decision record for the embedded section-level declaration marker.
- [`process-flow-diagram-standards.md`](../../../core/standards/process-flow-diagram-standards.md) — canonical per-class rendering authority for the process-flow classes (Mermaid syntax, ASCII flow-block, swimlane idiom), composed per the standard's § 6.
- [`docs/README.md`](../../../docs/README.md) — the established human-facing documentation home referenced by the audience arm (§ 4).
- Backfill tasks that cite this condition: **#3798** (DECLARE sweep), **#3441** (human-process BUILD). Spike of origin: **#3614** (D2). Parent epic: **#1173** / fission origin **#398**.

<!-- reference-durability: allow-link -->
# Per-Release Close-Out Learnings Register — Template

> **Source:** Stage 13 Close per-release close-out ceremony (Kerth retrospective + PMBOK 7 lessons-learned).
> **Consumer surface:** [`release/references/pipeline/stage-13-close.md`](../pipeline/stage-13-close.md) § 6 Outputs.
> **Placement:** This TEMPLATE is public (`release/references/templates/`). The FILLED per-release register writes to the operator-instance corpus root — `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/…` per [ADR-032](../../../core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md) (sibling to the instance `RELEASE_LOG`) — never the tracked tree.

---

## How to use

One filled register per release, authored by the operator at Stage 13 Close. The register is the human-authored full-ceremony reflection on the release; it **coexists** with the machine-generated `#### Release Learnings v<X.Y>` triple H4 block (emitted by [`synthesize-release-learnings.sh`](../../tools/synthesize-release-learnings.sh) at Stage 13 Phase A7). The relationship is directional: **the triple's three fields are seed inputs the operator transcribes and expands into this register's reflective sections** — the register consumes the triple; the triple has no dependency on the register and is unaffected by its absence.

Fill order:
1. Copy this template to the operator-instance register path for the closing version (under the `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/` corpus root per ADR-032).
2. Populate the **Header** (version + the triple's source-row anchors so the register is traceable to its captured events).
3. Run the **Kerth Retrospective** block (Prime Directive recited first; then the 3-question framework; then the ritual of closure).
4. Run the **PMBOK 7 Lessons-Learned** block (Situation → Outcome → Lessons → Next-cycle Actions).
5. Record the **Triple Linkage** subsection (which triple field seeded which register section).

| When | Who | Output |
|---|---|---|
| Stage 13 Close (per-release) | Operator | One filled register at the operator-instance register path |

**Format conventions:**
- Replace every `<…>` placeholder; remove the parenthetical prompts once filled.
- Keep section headers verbatim (consumers/audits grep for the Kerth Prime Directive line and the PMBOK 7 section names).
- This is a reflection artifact, not a status recap — name decisions, causes, and actions, not activity.

---

## Header

**Release version:** v<X.Y>
**Milestone:** <milestone-slug> (#<N>)
**Close date:** <YYYY-MM-DD>
**Release class:** <routine | novel | cross-cutting | hotfix>
**Triple source-row anchors:** `pipeline-event-log.md` row(s) at ts `<ts1>`[, `<ts2>`, …] (copy from the `#### Release Learnings v<X.Y>` H4 block's **Source-row anchors** line; `N/A` if the triple block rendered N/A)

---

## 1. Kerth Retrospective (full ceremony)

### 1.1 Prime Directive (recite before reflecting)

> Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand.

(The Prime Directive frames the retro as blameless. For a single-operator PMO it is recited as a discipline anchor — reflection targets the system and the process, never the person.)

### 1.2 Three-question framework

**What did we do well?** (keep-doing — the practices, decisions, or guardrails that worked and should be preserved)
- <…>

**What did we learn?** (new knowledge surfaced this release — seed from the triple's `Surprise` field, then expand)
- <…>

**What would we do differently?** (the change we would make if we ran this release again — seed from the triple's `Would-change` field, then expand)
- <…>

### 1.3 Ritual of closure

**Release closed for continuity:** <one line — name the release closed and the single most important learning carried forward. This is the ceremonial "we are done with this release; here is what we take with us" marker.>

---

## 2. PMBOK 7 Lessons-Learned (full ceremony)

One lesson per row is the unit; add rows as needed. Each lesson is self-contained (a future reader needs no other context).

### 2.1 Situation

(The context: what was being delivered, the conditions, the constraints, what made this release what it was. Seed from the triple's `Surprise` field where a surprise drove the situation.)
- <…>

### 2.2 Outcome

(What actually happened — the delivered result vs. the intended result; cite the Stage 13 goal-attainment verdict ATTAINED / PARTIALLY-ATTAINED / NOT-ATTAINED where relevant.)
- <…>

### 2.3 Lessons

(The extracted, generalizable lessons — what this release teaches that applies beyond it. Distinguish a one-off from a pattern.)

| # | Lesson | Type (one-off / pattern) | Evidence anchor |
|---|---|---|---|
| L1 | <…> | <…> | <file:line / issue # / event ts> |

### 2.4 Next-cycle Actions

(Concrete, owned, actionable items for the next release cycle — seed from the triple's `Would-change` (actions) + `Watch-for` (carry-forward monitoring) fields, then make each an action. A lesson without an action is an observation; this section is where lessons become work.)

| # | Action | Owner | Disposition (backlog issue # / carry-forward / accepted-residual) |
|---|---|---|---|
| A1 | <…> | <…> | <…> |

---

## 3. Triple Linkage (records the COEXIST relationship)

This register coexists with — and consumes — the machine-generated `#### Release Learnings v<X.Y>` triple H4 block. Record which triple field seeded which register section (so the directional triple → register relationship is auditable):

| Triple field | Verbatim value (from the H4 block) | Seeded into register section(s) |
|---|---|---|
| `Surprise` | <…> | 1.2 "what did we learn" / 2.1 Situation |
| `Would-change` | <…> | 1.2 "what would we do differently" / 2.4 Next-cycle Actions |
| `Watch-for` | <…> | 2.4 Next-cycle Actions (carry-forward watch) |

(If the triple block rendered `N/A — no novel learning this release`, record that here; the register's reflective sections may still carry operator-authored content that the machine triple did not capture.)

<!-- reference-durability: allow-link -->
# Product Owner ↔ Business Analyst boundary — extended reference

This reference holds the full deconfliction rationale for the `pmo-product-owner` (#1113) ↔ `pmo-business-analyst` (#1114) split. The SKILL.md `## Mode Selection` section carries the operative shared-verb disambiguation table and the one-sentence boundary rule; this document is the supporting rationale a reviewer or an editor consults when re-evaluating the split. It is reference-grade context, not a runtime gate.

## Why the split is legitimate — the ADR-019 3-conjunct boundary test

`pmo-product-owner` and `pmo-business-analyst` compose the **identical pair** (`pmo-process-designer` + `delivery-engine`). Per [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md), two Specialists may share a compose-pair only when all three boundary conjuncts hold simultaneously — a distinct primary role **AND** a distinct trigger surface **AND** a distinct write-scope. Both roles clear all three:

| ADR-019 conjunct | `pmo-product-owner` (#1113) | `pmo-business-analyst` (#1114) | Distinct? |
|---|---|---|---|
| **Distinct primary role** | Owns the **WHAT & WHY** — value, priority, backlog ordering, acceptance-of-value. Decides. | Owns the **HOW-it-works** — elicitation, requirements documentation, workflow, traceability, compliance. Documents/traces. | **YES** — decision-maker vs. analyst/documenter |
| **Distinct trigger surface** | "prioritize the backlog", "what's most valuable", "rank these stories", "is this ready to pull", "should we build or defer X", "write the story + acceptance criteria for [value]", "accept this story" | "elicit the requirements", "document this process/workflow", "build the traceability matrix", "trace requirement→Jira", "what's the gap between requirements and design", "map the as-is/to-be" | **YES** — value/priority/accept verbs vs. elicit/document/trace verbs |
| **Distinct write-scope** | The **prioritized backlog order**, the **value-ranked story** (title + value statement + accepted AC), the **include/defer/cut decision** | The **requirements set** (REQ-### structured docs), the **process/workflow documentation**, the **traceability matrix**, the **gap-analysis coverage matrix** | **YES** — backlog-ordering + accepted-story artifacts vs. requirements/traceability/process artifacts |

Because the split is only legitimate while all three conjuncts hold, a future edit that erodes any one of them (e.g., the PO starts emitting REQ-### sets, or the BA starts rendering value ranks) re-opens the cross-fire risk and must be re-reviewed against this table.

## The cross-fire risk and its guard

Trigger collision between #1113 and #1114 is the single highest-risk failure for this pair (tracked as R-DECONF in the v2.06 Stage 4 release plan; the two are evaluated **together** at Stage 7 Dev Testing). The risk is concrete: both roles compose `pmo-process-designer` Mode A (story/requirement authoring), so a phrase like "work on the requirements" or "write up these stories" surface-matches both skill descriptions.

The guard is the **decision-vs-documentation axis** encoded in the SKILL.md `## Mode Selection` shared-verb disambiguation table. A shared-verb request routes by which side of that axis its *primary need* falls on — deciding/accepting value (PO) versus eliciting/documenting/tracing the requirement (BA). When a request is genuinely mixed, the PO names the split and takes only the value/priority/acceptance half, deferring the documentation/traceability half to `pmo-business-analyst`. This behavior is also encoded as the SKILL.md mandatory cross-fire failure mode (`Cross-fires with business-analyst on the shared compose-pair — TRIG`).

## The boundary sentence (shared contract)

The one-sentence boundary rule is mirrored **verbatim** in both #1113's and #1114's SKILL.md for symmetry:

> The Product Owner decides value and priority and authors the backlog item the team commits to; the Business Analyst elicits, documents, and traces the requirement behind it — when a request is about **what to build next and whether its value is accepted**, it is PO; when it is about **how the requirement works and whether it traces**, it is BA.

If either skill's copy of this sentence is edited, the twin's copy must be updated in the same change — the sentence is a shared contract, and drift between the two copies is itself a deconfliction defect.

## Worked disambiguation examples

| Request as phrased | Primary need | Routes to | Why |
|---|---|---|---|
| "Which of these five stories should the team pull first?" | rank by value | **PO** | a prioritization decision, not a documentation task |
| "Write up the acceptance criteria so we can commit to STORY-12." | author + accept the committed item | **PO** | the item the team commits to, with accepted AC |
| "Document the as-is order-to-cash workflow." | process documentation | **BA** | a workflow document, no value decision |
| "Trace these requirements back to the FDD." | traceability | **BA** | a traceability matrix, the analysis chain |
| "We need the requirements for the partner-onboarding epic." | (mixed) | **split** | PO takes the value-ranked, acceptance-bearing backlog items; BA takes the structured REQ-### set + traceability |
| "Is the backlog ready for next sprint?" | ready-and-most-valuable | **PO** | DoR bound to value-rank (Mode 3); BA's "ready" is requirements-complete/traceability-intact |

## Cross-references

- [ADR-019 — Specialists compose, not absorb](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md) — the 3-conjunct boundary test and the compose-by-invocation rule.
- [`failure-mode-standard.md`](../../../../core/specs/failure-mode-standard.md) — the 5-field template the SKILL.md cross-fire failure mode follows.
- `pmo-business-analyst` (#1114) SKILL.md — the twin; carries the verbatim boundary sentence and the symmetric cross-fire failure mode.

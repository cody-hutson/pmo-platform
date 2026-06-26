<!-- reference-durability: allow-link -->
# Business Analyst ↔ Product Owner boundary — extended reference

This reference holds the full deconfliction rationale for the `pmo-business-analyst` ↔ `pmo-product-owner` split. The SKILL.md `## Mode Selection` section carries the operative shared-verb disambiguation table and the one-sentence boundary rule; this document is the supporting rationale a reviewer or an editor consults when re-evaluating the split. It is reference-grade context, not a runtime gate. Its content is the symmetric twin of `pmo-product-owner`'s `references/po-ba-boundary.md` — the two are written from opposite role perspectives but assert the **identical** boundary; if one is edited, the other must be updated in the same change.

## Why the split is legitimate — the ADR-019 3-conjunct boundary test

`pmo-business-analyst` and `pmo-product-owner` compose the **identical pair** (`pmo-process-designer` + `delivery-engine`). Per [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md), two Specialists may share a compose-pair only when all three boundary conjuncts hold simultaneously — a distinct primary role **AND** a distinct trigger surface **AND** a distinct write-scope. Both roles clear all three:

| ADR-019 conjunct | `pmo-business-analyst` | `pmo-product-owner` | Distinct? |
|---|---|---|---|
| **Distinct primary role** | Owns the **HOW-it-works** — elicitation, requirements documentation, workflow, traceability, compliance. Documents/traces. | Owns the **WHAT & WHY** — value, priority, backlog ordering, acceptance-of-value. Decides. | **YES** — analyst/documenter vs. decision-maker |
| **Distinct trigger surface** | "elicit the requirements", "document this process/workflow", "build the traceability matrix", "trace requirement→Jira", "what's the gap between requirements and design", "map the as-is/to-be" | "prioritize the backlog", "what's most valuable", "rank these stories", "is this ready to pull", "should we build or defer X", "write the story + acceptance criteria for [value]", "accept this story" | **YES** — elicit/document/trace verbs vs. value/priority/accept verbs |
| **Distinct write-scope** | The **requirements set** (REQ-### structured docs), the **process/workflow documentation**, the **traceability matrix**, the **gap-analysis coverage matrix** | The **prioritized backlog order**, the **value-ranked story** (title + value statement + accepted AC), the **include/defer/cut decision** | **YES** — requirements/traceability/process artifacts vs. backlog-ordering + accepted-story artifacts |

Because the split is only legitimate while all three conjuncts hold, a future edit that erodes any one of them (e.g., the BA starts rendering value ranks, or the PO starts emitting REQ-### sets) re-opens the cross-fire risk and must be re-reviewed against this table.

## The cross-fire risk and its guard

Trigger collision between `pmo-business-analyst` and `pmo-product-owner` is the single highest-risk failure for this pair (tracked as R-DECONF in the v2.11 Stage 4 release plan; the two are evaluated **together** at Stage 7 Dev Testing). The risk is concrete: both roles compose `pmo-process-designer` Mode A (story/requirement authoring), so a phrase like "work on the requirements" or "write up these stories" surface-matches both skill descriptions.

The guard is the **documentation-vs-decision axis** encoded in the SKILL.md `## Mode Selection` shared-verb disambiguation table. A shared-verb request routes by which side of that axis its *primary need* falls on — eliciting/documenting/tracing the requirement (BA) versus deciding/accepting value (PO). When a request is genuinely mixed, the BA names the split and takes only the elicitation/documentation/traceability half, deferring the value/priority/acceptance half to `pmo-product-owner`. This behavior is also encoded as the SKILL.md mandatory cross-fire failure mode (`Cross-fires with product-owner on the shared compose-pair — TRIG`).

## The boundary sentence (shared contract)

The one-sentence boundary rule is mirrored **verbatim** in both `pmo-business-analyst`'s and `pmo-product-owner`'s SKILL.md for symmetry:

> The Product Owner decides value and priority and authors the backlog item the team commits to; the Business Analyst elicits, documents, and traces the requirement behind it — when a request is about **what to build next and whether its value is accepted**, it is PO; when it is about **how the requirement works and whether it traces**, it is BA.

If either skill's copy of this sentence is edited, the twin's copy must be updated in the same change — the sentence is a shared contract, and drift between the two copies is itself a deconfliction defect.

## Worked disambiguation examples

| Request as phrased | Primary need | Routes to | Why |
|---|---|---|---|
| "Document the as-is order-to-cash workflow." | process documentation | **BA** | a workflow document, no value decision |
| "Trace these requirements back to the FDD." | traceability | **BA** | a traceability matrix, the analysis chain |
| "Elicit the requirements for the partner-onboarding epic." | elicitation | **BA** | a structured REQ-### set, the analysis behind the backlog |
| "What's the gap between the requirements and the design?" | coverage gap | **BA** | requirements-vs-design coverage, not value-coverage |
| "Which of these five stories should the team pull first?" | rank by value | **PO** | a prioritization decision, not a documentation task |
| "Write up the acceptance criteria so we can commit to STORY-12." | author + accept the committed item | **PO** | the item the team commits to, with accepted AC |
| "We need the requirements for the partner-onboarding epic." | (mixed) | **split** | BA takes the structured REQ-### set + traceability; PO takes the value-ranked, acceptance-bearing backlog items |
| "Is the backlog ready for next sprint?" | (mixed) | **split** | BA's "ready" is requirements-complete/traceability-intact; PO's "ready" is DoR bound to value-rank (its Mode 3) |

## Cross-references

- [ADR-019 — Specialists compose, not absorb](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md) — the 3-conjunct boundary test and the compose-by-invocation rule.
- [`failure-mode-standard.md`](../../../../core/standards/failure-mode-standard.md) — the 5-field template the SKILL.md cross-fire failure mode follows.
- `pmo-product-owner` SKILL.md — the twin; carries the verbatim boundary sentence and the symmetric cross-fire failure mode.

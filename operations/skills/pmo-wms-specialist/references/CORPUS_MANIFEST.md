<!-- reference-durability: allow-link -->
# WMS Corpus Manifest

> **ILLUSTRATIVE pilot corpus.** The documents listed below are a clearly-labelled illustrative
> reference set for a *generic* warehouse management system — authored to validate the
> System-Specialist template end-to-end (AC-4), NOT documentation of any real vendor product or live
> deployment. A production `pmo-wms-specialist` instance replaces this corpus with the operator's
> actual supplied WMS documentation and re-fills this manifest.

## System

- **System name:** WMS (warehouse management system) — generic/illustrative
- **Short label:** WMS
- **Corpus root:** `references/corpus/`
- **Manifest last updated:** 2026-07-01

## Ingested documents

| # | Document (file under `references/corpus/`) | Type | Source / origin | Version | Doc date | Ingested | Coverage (what it documents) |
|---|---|---|---|---|---|---|---|
| 1 | [`module-reference.md`](corpus/module-reference.md) | module reference | illustrative (pilot) | v1.0 | 2026-07-01 | 2026-07-01 | Entities (item, location, wave, order, task) + core workflows (receiving/putaway, wave planning, allocation, picking, replenishment, shipping) |
| 2 | [`configuration-notes.md`](corpus/configuration-notes.md) | configuration notes | illustrative (pilot) | v1.0 | 2026-07-01 | 2026-07-01 | Configurable options the corpus documents (allocation strategy, replenishment trigger, wave-release policy) + stated constraints |
| 3 | [`runbook.md`](corpus/runbook.md) | runbook | illustrative (pilot) | v1.0 | 2026-07-01 | 2026-07-01 | Operational procedures (release a wave, resolve a short-pick, trigger replenishment) + integration edges (order source, carrier, inventory master) |

## Known coverage gaps

Areas the illustrative corpus does **not** cover — the questions the WMS Specialist must **refuse**
(and name this gap) rather than answer. These are the direct targets of the AC-4 out-of-corpus
refusal eval (R2/R3).

| Gap (uncovered area) | Why it matters | Resolution (doc to add / vendor route) |
|---|---|---|
| Labor management / task interleaving | operators ask about labor standards and task prioritization; corpus is silent | add the labor-management module doc, or route to vendor |
| Cycle-count / physical-inventory procedures | a common WMS question; not in the pilot corpus | add the inventory-control doc |
| API field-level schemas for the order/carrier integrations | integration work needs field detail; corpus states only which systems connect, not the payloads | add the API reference |
| Yard / dock-door / appointment scheduling | out of scope for the pilot corpus | add the yard-management doc |

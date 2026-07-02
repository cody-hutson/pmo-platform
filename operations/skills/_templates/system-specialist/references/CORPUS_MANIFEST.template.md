<!-- reference-durability: allow-link -->
# {{SYSTEM_NAME}} Corpus Manifest

> **Skeleton — copy, do not edit in place.** An instance copies this file to its own
> `references/CORPUS_MANIFEST.md` and fills the rows with the actual ingested docs. This
> skeleton in the template directory stays blank (no per-system facts — AC-1). The manifest is
> the record of what the instance ingested; it defines the boundary of the Specialist's
> authority (the grounding contract answers only from docs listed here).

## System

- **System name:** {{SYSTEM_NAME}}
- **Short label:** {{SYSTEM_SHORT}}
- **Corpus root (`{{CORPUS_PATH}}`):** `references/` (this instance's corpus directory)
- **Manifest last updated:** {{YYYY-MM-DD}}

## Ingested documents

One row per ingested document. `version` and `doc date` let the grounding contract flag corpus
staleness against a system version in question.

| # | Document (file under `references/`) | Type | Source / origin | Version | Doc date | Ingested | Coverage (what it documents) |
|---|---|---|---|---|---|---|---|
| 1 | | module guide / config export / API ref / runbook / other | | | | {{YYYY-MM-DD}} | |
| 2 | | | | | | | |

## Known coverage gaps

Areas of {{SYSTEM_NAME}} the corpus does **not** cover — the questions the Specialist must
refuse (and name this gap) rather than answer. Keeping this current is what lets the grounding
contract refuse precisely instead of guessing.

| Gap (uncovered area) | Why it matters | Resolution (doc to add / vendor route) |
|---|---|---|
| | | |

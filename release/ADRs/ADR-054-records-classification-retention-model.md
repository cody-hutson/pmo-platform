<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Records classification + retention model — 4-class value-based taxonomy, derived not minted, destruction=none
status: Accepted
date: 2026-06-30
release: 20-records-management-naming-and-cleanup
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Collective Review scope-lock"
tags: [records-management, retention, classification, disposition, iso-15489, derived-class, least-destructive-disposition, authenticity-markers, reversibility-moderate]
---

# ADR-054 — Records classification + retention model

## Status

**Accepted** — scope-locked at the Collective Review (2026-06-30); the governance write lands on the release branch + PR, with PR-review at Stage 9 as the dry-run gate (Claude Code path).

Number **054** — next gap-free after 053 (`pre-gate-eligibility-forcing-function`); `check-adr-numbers.py` reports contiguous 001..053 at the authoring commit. Referenced by **slug** (`records-classification-retention-model`), never by integer, so the number re-resolves if a concurrent release claims 054 first. Binds atomically at Stage 12.

## Context

The workspace had only **fragments** of records management — `projects/Archive/` for closed projects, an `08-Generated/` 10-business-day auto-archive note, and a "Vital classification" the pipeline-event-log schema already applied — but no coherent policy covering retention, classification, disposition, and authenticity as ISO 15489-1 frames it.

Crucially, the corpus was **already writing IOUs against a non-existent policy.** `pipeline-event-log-schema.md:194` literally states *"its archives carry the Vital classification per the records-management policy,"* and `km-governance-framework.md` §6.2 reserves a COMPOSE seam to the policy "when shipped." So this decision is **canonicalization-by-reconciliation**, not green-field invention: the 4-class taxonomy, the destruction stance, and the Vital ≥ 3-year period already lived in the corpus and had to be adopted verbatim.

Three design questions had to be settled: **(1)** what *carries* a record's class — a new minted field, or derivation from existing fields; **(2)** whether the classification function covers the *full* governed record population or only the record types the source fragments happened to name; and **(3)** the disposition stance — does a records policy introduce a "destroy after N years" clock, against a corpus-wide least-destructive-disposition discipline.

## Decision

**Adopt the ISO 15489-1 four-class value-based taxonomy (vital / important / reference / transient); derive a record's class from existing fields rather than minting a `records_class:` field; make the derivation total over every `01-08` home plus a named `DEFAULT = Reference` fallback; pin retention by class with a destruction stance of none (least-destructive-disposition); and map ISO authenticity characteristics onto existing frontmatter fields. Home the policy at `core/governance/RECORDS_POLICY.md` with a named, axiomatically-permanent archive log `core/governance/RECORDS_ARCHIVE_LOG.md`.**

1. **Class is derived, not minted — forced by duplicate-source-discipline §1.** A record's class is read off (a) its governed home + (b) its existing `trust_category` + (c) its `lifecycle_state`. Minting a `records_class:` frontmatter field would duplicate carriers the platform already holds and require a corpus-wide backfill. Derivation keeps the scheme queryable from existing data.

2. **The derivation is total over the governed population.** Every one of the eight canonical project folders (`01-Governance` … `08-Generated`) resolves to exactly one class, and a named **DEFAULT = Reference** fallback covers any home or record type not matched by an explicit row. A partial scheme that classifies only the source-named record types fails *silently* — an `02-Design`, `03-Testing`, or `04-PMO-Operations` record would have a home but no derivable class. Totality (every home maps + a named default) makes the function provably complete at the cost of three extra table rows and one default sentence.

3. **Destruction = none — adopt the corpus-wide stance verbatim.** The platform does not destroy records; disposition is a move or a presence-preserving redaction. This is the least-destructive-disposition discipline already in force (pipeline-event-log-schema §7 "Destruction policy: None. Append-only forever"; km-governance §4.3 "retirement is NOT deletion"). File deletion remains an independent operator-authorized decision-class outside this policy. The low-regulatory posture (no SOX/HIPAA/GDPR today) means no destruction clock is owed; one is added only by amendment if a regime attaches.

4. **Authenticity maps onto existing fields.** The four ISO characteristics (authentic / reliable / integrity / usability) are evidenced by `source_inputs` + git authorship, `trust_category`, git commit hash + `lifecycle_state`/`approval_state`, and governed-home placement respectively — no new authenticity field. (`review_status` is the template-protocol lifecycle field, NOT a record field — a disambiguation note in the policy prevents the collision.)

5. **The archive log is the disposition base case.** `RECORDS_ARCHIVE_LOG.md` is permanent and append-only by axiom — Vital by definition, never itself disposed, and no self-referential row is ever written for it. This terminates the otherwise-unbounded recursion ("what logs the disposition of the archive log?").

## Alternatives considered

- **Mint a `records_class:` frontmatter field stamped per record** — rejected: duplicates existing carriers (`trust_category` + home + `lifecycle_state` already determine class) and forces a corpus-wide backfill, violating duplicate-source-discipline §1. Derivation over existing fields is the lower-regret choice.
- **Partial classification (map only the source-named record types)** — rejected: leaves `02-Design`/`03-Testing`/`04-PMO-Operations` with no derivable class; the scheme would *look* complete because every example classifies, while failing silently the first time someone classified an FDD or a test plan. The total function + named default closes this at trivial cost.
- **Introduce a "destroy after N years" retention clock** — rejected: contradicts ≥ 6 canonical corpus surfaces that declare least-destructive-disposition; introducing a destruction clock here would itself be a best-practices conflict. No regulatory regime owes one today.
- **Co-locate the policy with peer K1 frameworks in `core/standards/`** — deferred (not rejected on merits): the home was reconciled to `core/governance/` at Mode R; relitigating it here would contradict the approved plan. The placement asymmetry (the policy is the 8th K1 framework but homes in `core/governance/` while the other 7 live in `core/standards/`) is logged as an accepted residual + routed to a next-release `observation.yml` candidate (the N=8 cleave trigger).

## Consequences

- The platform gains a single coherent records-management contract; record handling stops being ad-hoc. The disposition discipline is unified corpus-wide under one named policy.
- **Forward-references resolve.** The verified literal-phrase blast radius is **2 surfaces** (not the 7 the original spec intuited): **1 hard IOU** (`pipeline-event-log-schema.md:194`) that resolves cleanly with no edit, and **1 soft COMPOSE seam** (`km-governance-framework.md §6.2`) that defers to the policy-when-shipped and needs no edit this card. A handful of further surfaces mention retention/disposition generally but explicitly defer their *engine* to a future scope (e.g. `tracker-schemas.md` — "the records-management/retention policy engine is out of scope here") and are NOT this policy's concern.
- The policy owns no mechanism an existing protocol already owns (the `08-Generated/` sweep, the maturity/promotion fields, KM-retirement, the closed-projects archive location all stay owned where they live). It composes by reference.
- A placement asymmetry with the `core/standards/` peer frameworks is accepted as a documented residual, routed to a future structure-review observation.
- Regulatory retention is deferred until a regime attaches; the destruction stance is the load-bearing disposition decision and is MODERATE-reversible (a future clock is a governance-gated amendment).

## Reversibility

**MODERATE / Confidence HIGH.** The policy doc, archive log, and OPERATIONS.md link are individually CHEAP to reverse (`git revert` the release PR; a `git mv` reverses the home). The load-bearing decision — destruction = none — is MODERATE: once the disposition discipline is unified under this policy and consumers rely on it, introducing a destruction clock later is a policy amendment through the governance gate rather than a free edit. Confidence is HIGH that the derived-not-minted, total-function, and destruction=none choices are correct: each was forced by a named constraint (duplicate-source-discipline §1; the silent-failure of a partial derivation; ≥ 6 corpus surfaces declaring least-destructive-disposition), not by preference.

## Related ADRs

- **ADR-052** (engineering parallelism postures) — sibling release-ops ADR from a concurrent line; precedent for the slug-referenced, integer-rebinds-at-Stage-12 ADR-numbering discipline used here.
- **ADR-050** (deliverable-domain axis) — precedent for deriving a classification from existing fields + an open/total scheme over a named default rather than minting a new closed field.

---
title: Records Archive Log
purpose: The append-only ledger of every records-disposition move governed by RECORDS_POLICY.md — one row per archival move (project-CLOSED or retention age-out). The policy-level disposition audit trail.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
owner: operator-class:Workspace owner ([OPERATOR_NAME])
consumers: RECORDS_POLICY.md § Disposition Rules (rule 3 — the ledger this log realizes); project-initiator (Closure mode — writes a row on project-CLOSED disposition); artifact-workflow-protocol §4 + pipeline-event-log-schema §7 (age-out sweeps that emit a policy-level ledger row)
---
<!-- reference-durability: allow-link -->

# Records Archive Log

**Purpose:** The append-only ledger of every records-disposition move governed by [`RECORDS_POLICY.md`](RECORDS_POLICY.md) § Disposition Rules — one row per archival move.
**Organization:** One row per move, in the column contract below. Append-only; rows are never edited or deleted.
**Governance:** [`RECORDS_POLICY.md`](RECORDS_POLICY.md) § Disposition Rules (rule 3).
**Layer:** 1 (Engineering, git-tracked).

**Base-case axiom.** This log is **permanent and append-only by definition — it is the disposition base case** (the axiom that terminates the records-classification recursion). It is itself a **Vital** record by axiom (not by deriving its own class through the policy's classification test). It is **never** subject to a disposition move, and **no self-referential archive-log row is ever written for it.**

## Disposition Log

One row per archival move. `trigger` is one of `{project-CLOSED, age-out}`.

| date | record (path / id) | class | trigger | from → to | actor |
|---|---|---|---|---|---|
| 2026-08-03 | `release/releases/RELEASE_LOG.md` — 147 aged-out `#### Deployment Log` block bodies (the 8-column release table, all 9 newer Deployment-Log blocks, and all 8 `#### Release Learnings` blocks were NOT moved) | Vital (segments inherit the parent's class) | age-out | `release/releases/RELEASE_LOG.md` → `release/releases/RELEASE_LOG_ARCHIVE-{v1,v2,v3,version-less}.md` (4 segments, same directory) | `release/tools/sweep-release-corpus.py --apply`, release `{{RELEASE_VERSION}}` |

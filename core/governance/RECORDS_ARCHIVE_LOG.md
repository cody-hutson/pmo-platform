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
| 2026-08-01 | `release/releases/RELEASE_LOG.md` — Deployment Log + Release Learnings bodies, 160 aged-out releases | Vital | age-out | `RELEASE_LOG.md` → `RELEASE_LOG_ARCHIVE-{v1,v2,v3,v4,_unversioned}.md` (same directory) | `sweep-release-corpus.py` |
| 2026-08-01 | `release/releases/RELEASE_DIGEST.md` — entry bodies, 160 aged-out releases, plus the legacy `### Releases` table (11 rows, migrated verbatim) | Vital | age-out | `RELEASE_DIGEST.md` → `RELEASE_DIGEST_ARCHIVE-{v1,v2,v3,v4,_unversioned}.md` (same directory) | `sweep-release-corpus.py` |
| 2026-08-01 | `release/releases/RELEASE_INDEX.md` — Theme-column prose, 160 aged-out releases (rows, order and the five verified columns untouched) | Vital | age-out | `RELEASE_INDEX.md` → `RELEASE_INDEX_ARCHIVE-{v1,v2,v3,v4,_unversioned}.md` (same directory) | `sweep-release-corpus.py` |
| 2026-08-01 | `CHANGELOG.md` — release-section bodies, 160 aged-out releases (`## [Unreleased]` and every section heading retained) | Vital | age-out | `CHANGELOG.md` → `CHANGELOG_ARCHIVE-{v1,v2,v3,v4,_unversioned}.md` (repository root, same directory) | `sweep-release-corpus.py` |

**Sweep note (2026-08-01).** One sweep, four ledgers, 20 segments. Combined working set 1,549,157 B → 262,161 B (83.1% reduction) against a 300,000 B ceiling. Trigger is age-out; the number of releases retained (4) is an **output** of the byte rule, not a parameter to it. Disposition is a move: every relocated entry keeps its heading in its source ledger with a pointer to its segment, and conservation was asserted at **both** ends — 571 relocated entries reconciled against the pre-sweep tree, with the verifier first falsified against a deliberately truncated segment so the PASS is evidence rather than assertion.

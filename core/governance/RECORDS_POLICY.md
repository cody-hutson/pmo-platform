---
title: Records Management Policy
purpose: The canonical retention / classification / disposition / authenticity policy for the workspace's governed records — the single contract for how long records are kept, what class they hold, how they are disposed (never destroyed), and how their authenticity is evidenced. Implements the ISO 15489-1 value-based records model over the platform's existing fields and folders; owns no mechanism an existing protocol already owns.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
owner: operator-class:Workspace owner ([OPERATOR_NAME])
consumers: pipeline-event-log-schema §7; km-governance-framework §6.2; artifact-generator; project-initiator (Closure mode); pmo-qa-auditor
adr: records-classification-retention-model
---
<!-- reference-durability: allow-link -->

# Records Management Policy

**Scope:** All governed records across the workspace — the `01-08` project folders, the K1 codified corpus, the release audit trail, and the operational trackers. **Status:** ACTIVE.

This policy is the records **contract**: it states the classification, the retention period, the disposition rule, and the authenticity markers for each governed record class. It owns **no mechanism** that an existing protocol already owns — it composes by reference (the `08-Generated/` sweep, the maturity/promotion fields, the KM-retirement protocol, and the closed-projects archive location all stay owned where they already live; see § Composition Boundaries). The policy is a set of **durable structures** (the tables below), not prose.

## ISO 15489-1 Fit

This policy implements the ISO 15489-1:2016 records model: it classifies records by **continuing business value** (not by format), and it evidences the four ISO record characteristics — **authentic / reliable / integrity / usability** (§ Authenticity Markers). It does **not** import a regulatory retention schedule: the workspace carries no SOX / HIPAA / GDPR exposure today. If a regulatory regime later attaches, a mandated destruction clock is added by amendment via the governance gate (re-triage to P1 at that point); until then, no destruction clock is owed.

## Classification Scheme

A record's class is one of four ISO 15489-1 classes — **vital / important / reference / transient** — set by its **continuing business value**, not its format.

The class is **derived, not stamped.** There is no `records_class:` frontmatter field. A record's class is read off three values the platform already carries: (a) its governed **home** (which `01-08` folder, or which corpus location), (b) its existing `trust_category` (`evidence` / `controlled-truth` / `interpretation` / `working-context` / `historical-record`), and (c) its `lifecycle_state`. Deriving the class from existing fields keeps the scheme queryable from data the platform already holds and avoids minting a redundant field (duplicate-source-discipline §1).

The classification function is **total** over the governed record population: every one of the eight canonical project folders (`01-Governance` … `08-Generated`) resolves to exactly one class, and a named **DEFAULT = Reference** fallback covers any home or record type not matched by an explicit row. A reader classifying any governed record always gets an answer.

### Classification table — every `01-08` home maps to exactly one class

| Home (canonical folder) | Class | Derivation rule (home + `trust_category` + `lifecycle_state`) | Concrete record types |
|---|---|---|---|
| `01-Governance/` | Important | governed-project home + `trust_category: controlled-truth` ⇒ Important | charters, project plans, SOWs, approval records, cutover/go-live plans, comms plans, stakeholder maps |
| `02-Design/` | Important | design home + `trust_category: controlled-truth`/`interpretation` ⇒ Important (recoverable at material cost; needed for the work duration + a tail) | FDDs, process flows, architecture docs, project-authored training plans and materials |
| `03-Testing/` | Important | testing home + `trust_category: evidence` (results) or `controlled-truth` (plans) ⇒ Important | test plans, test scripts, defect exports, QA/UAT results, test-related Jira exports |
| `04-PMO-Operations/` | Important | operational home + Document Tier 2 (the agent's operational memory) ⇒ Important | skill-managed operational trackers — Daily Status Log, Communications Tracker, Open Meetings Tracker, Transcript Register, carry-forward trackers |
| `05-Transcripts/` | Reference | raw-evidence home + `trust_category: evidence`, consult-not-authoritative ⇒ Reference | meeting recordings and transcriptions (raw evidence, never modified after filing) |
| `06-Emails/` | Reference | raw-evidence home + `trust_category: evidence` ⇒ Reference | archived email threads, Teams message exports, comms digests |
| `07-Reference/` | Reference | external-reference home, supersedable by re-acquisition ⇒ Reference | SOPs, runbooks, vendor documentation, external material |
| `08-Generated/` (unreviewed) | Transient | staging home + `trust_category: working-context` + unreviewed ⇒ Transient | generated artifacts pending promotion |
| **DEFAULT (any home / type not matched above)** | **Reference** | **fallback axiom — any governed record not resolved by a row above classifies Reference until an explicit row is added; the gap is then surfaced as an `observation.yml` candidate. A Reference default is the least-destructive safe assignment: longest sensible retention, no fast disposition.** | (catch-all — keeps the derivation function total) |

### Cross-cutting record types (class set by kind, not folder)

Some governed records are not in the `01-08` project tree; their class is set by **kind**:

| Record kind | Class | Why |
|---|---|---|
| `pipeline-event-log.md` + quarterly archives | Vital | the platform's operational audit trail; loss is unrecoverable |
| `RELEASE_LOG.md` | Vital | release project-of-record; the permanent release audit trail |
| `RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, `CHANGELOG.md` (the three **derived** release ledgers) | **Important** | **Projected, but NOT reproducible.** Each is emitted entry-by-entry by one projector (`release-corpus-schema.md` § Derived-Surface Contract), so *new* entries are derivable — but the shipped files hold **317 sole-copy fields** whose only home is the file itself: the INDEX `Theme` column has no source outside the INDEX, and the majority of historical DIGEST headlines and CHANGELOG summaries were edited by the operator **after** emission. They are therefore **not** `Reference` — that class is defined as *supersedable by re-acquisition*, and there is nothing to re-acquire these from — and emphatically not `Transient`. Loss is recoverable only from git history, at material cost: `Important`. |
| ADRs (`release/ADRs/`, `core/ADRs/`) | Vital | immutable decision record (Nygard form — superseded by a successor ADR, never deleted) |
| Governance docs (CLAUDE.md, OPERATIONS.md, RECORDS_POLICY.md, RELEASE_PROTOCOL.md) | Vital | without them the operational/legal state could not be re-established |
| `CORRECTIONS.md` entries (pre-graduation) | Transient | working redirects; eligible for the fastest disposition until graduated-or-expired |
| scratch / intermediate working artifacts | Transient | no continuing value past their immediate use (intermediate-artifact discipline) |

**Class definitions (ISO 15489-1 business-value test):**

| Class | Business-value test |
|---|---|
| **Vital** | Records without which the organization could not re-establish its operational/legal state; loss is unrecoverable. |
| **Important** | Records whose loss is recoverable but at material cost/effort; needed for the duration of the work + a tail. |
| **Reference** | Records consulted for context but not themselves authoritative; supersedable by re-acquisition. |
| **Transient** | Working/ephemeral records with no continuing value past their immediate use; eligible for the fastest disposition. |

## Retention Schedule

Keyed by record type → retention period + disposition location. "Retention" is the **minimum** the record is preserved before it is *eligible* for disposition; per § Disposition Rules the disposition is never destruction. Retention periods reference their source-of-truth where one exists (the Vital ≥ 3-year period is ISO 15489-1:2016; the 10-business-day and emergence windows are owned by the cited protocols) — parameterize-over-hardcode.

| Record type (concrete platform artifact) | Class | Retention period | Disposition location (on age-out / trigger) |
|---|---|---|---|
| `pipeline-event-log.md` + quarterly archives | Vital | **≥ 3 years** (ISO 15489-1:2016 Vital) | `pipeline-event-log-archive-YYYY-QN.md` in place (quarterly sweep owned by `pipeline-event-log-schema.md` §7) |
| `RELEASE_LOG.md` (release audit trail) | Vital | **Permanent** (project-of-record; never aged out) | retained in place **or in a same-directory archive segment**; superseded rows annotated, never deleted. The 8-column release table is **never** split — four consumers enumerate it by field position. Only aged-out `#### Deployment Log` block **bodies** relocate, to `RELEASE_LOG_ARCHIVE-<family>.md` beside the parent, and each keeps its **heading plus a pointer** in the parent so every `links.log_anchor` and in-corpus anchor still resolves — the redaction-preserves-presence shape of § Disposition Rules rule 2. `#### Release Learnings` blocks are **never** relocated at any window: their bodies are machine-read by a named consumer that degrades to a "no novel learning" sentinel at exit zero when the body is absent, which would make the record assert the opposite of the truth. A segment **inherits its parent's class** — it is a disposition *destination*, never itself a disposition *source*, and is never eligible for a disposition its parent is not. Mechanism owned by `release/tools/sweep-release-corpus.py`; the trigger is a byte budget on the hot file, so the retained-release count is an output of the rule and never an input to it. |
| `RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, `CHANGELOG.md` (derived release ledgers) | Important | **Permanent while the corpus is live** (each is a published navigation/user-facing surface; no age-out) | retained in place. **NEVER REGENERATED WHOLE.** Entries are appended or prepended one at a time by the projector; a whole-file regenerate is a **destruction event**, not a refresh — it silently overwrites the 317 sole-copy fields named in the classification table above and surfaces as a clean diff rather than a conflict, so nothing flags it. A row or entry is reconciled **in place**, against the field's declared source. Historical entries are never rewritten to match a later convention; the INDEX carries a standing grandfathering statement in its own header for exactly this reason. |
| ADRs (`release/ADRs/`, `core/ADRs/`) | Vital | **Permanent** (immutable decision record) | retained in place; superseded via a successor ADR, never edited/deleted |
| Governance docs (CLAUDE.md, OPERATIONS.md, this policy, RELEASE_PROTOCOL.md) | Vital | **Permanent** while ACTIVE; on retirement → historical | retained; retirement is a `lifecycle_state: archived` content event (km-governance §4), not a file delete |
| `01-Governance/` project artifacts (charters, plans, approval records) | Important | **Project lifetime + 1 yr** after CLOSED | `projects/Archive/<Project>/` (closed-projects archive, Layer 2) |
| `02-Design/` artifacts (FDDs, process flows, architecture, training) | Important | **Project lifetime + 1 yr** after CLOSED | `projects/Archive/<Project>/` |
| `03-Testing/` artifacts (test plans, scripts, defect exports, QA/UAT) | Important | **Project lifetime + 1 yr** after CLOSED | `projects/Archive/<Project>/` |
| `04-PMO-Operations/` operational trackers (Document Tier 2) | Important | **Project lifetime** (operational memory) | `projects/Archive/<Project>/` at project close |
| RAID logs (`[Project]_RAID_Log.csv`) | Important | **Project lifetime**; closed items to the log's ARCHIVE section, never purged | in-file ARCHIVE section → `projects/Archive/` at project close |
| Raw evidence archives (`05-Transcripts/`, `06-Emails/`) | Reference | **Project lifetime + 1 yr** after CLOSED | `projects/Archive/<Project>/` (raw-archive — never deleted, never modified) |
| External reference material (`07-Reference/`: SOPs, vendor docs) | Reference | **While the referencing project is ACTIVE**; re-evaluated at close | `projects/Archive/<Project>/` or discard-if-superseded-externally (operator call at close) |
| Generated artifacts in `08-Generated/`, unreviewed | Transient | **10 business days** unreviewed | `08-Generated/_archived/` via the `promotion_state: staged → archived-in-place` sweep — **mechanism owned by `artifact-workflow-protocol.md` §4**, classified here only |
| `CORRECTIONS.md` entries | Transient | until graduated-or-expired (N=2 / 180-day emergence per OPERATIONS.md § CORRECTIONS) | archived into the Pattern-Review Decision-Briefing record on graduation (encode-and-evict) — mechanism owned there, classified here |
| any record not matched above (DEFAULT) | Reference | **Project lifetime + 1 yr** after CLOSED (the safe least-destructive default) | `projects/Archive/<Project>/` |

No retention period is invented where one already exists — each row adopts or generalizes a value already in the corpus. The only *new* values are the +1-yr closed-project tails, the "Permanent" designations for `RELEASE_LOG`/ADRs/governance, and the derived-ledger row above — all of which make an existing "never deleted/purged" stance explicit in class language rather than introducing a new period.

**A note on why "derived" does not mean "disposable."** The three derived ledgers are the one place in this policy where the two axes come apart: they are *machine-projected* on the emit path and *sole-copy* in their history. Classifying them by their emit path alone would resolve them to the DEFAULT `Reference` row — and `Reference` licenses re-acquisition, which for these files means regenerating them, which destroys the content that made them worth retaining. The classification is therefore made **explicitly**, so the DEFAULT never reaches them.

## Disposition Rules

All three sub-rules are stated unconditionally.

1. **Archival trigger.** A record becomes eligible for archival when **either** holds:
   (a) its owning project transitions to **CLOSED** (the project-lifecycle terminal — `project-initiator` Closure mode moves the project tree to `projects/Archive/`), **or**
   (b) **retention age-out** — the record's retention period (Retention Schedule) elapses (e.g., the 10-business-day `08-Generated/` sweep; the quarterly `pipeline-event-log` archive).

2. **Destruction stance — none.** The platform **does not destroy records.** This is the least-destructive-disposition discipline already in force corpus-wide. Disposition is a **move** (to an archive location) or, where content must be removed for cause, a **redaction** that preserves the record's *presence* (`[REDACTED for <reason>]`, emitting a tracking event — the pattern `pipeline-event-log-schema.md` §7 specifies). Deletion of a record file is an independent operator-authorized decision-class **outside this policy's scope** (the stance `km-governance-framework.md` §4.3 states for retirement). The low-regulatory-risk posture means no destruction clock is owed today; one is added only by amendment if a regulatory regime attaches.

3. **Archive log.** Every archival move is logged to a named archive log: `core/governance/RECORDS_ARCHIVE_LOG.md`. One row per move: `date · record (path/id) · class · trigger {project-CLOSED | age-out} · from → to · actor`. For the `08-Generated/` sweep and the quarterly `pipeline-event-log` archive, the archive-log row is the *policy-level* ledger entry; the *mechanism* stays owned by the respective protocol (the policy records that the move happened and under what trigger; it does not re-own the sweep).

   **Base-case axiom (terminates the recursion).** The `core/governance/RECORDS_ARCHIVE_LOG.md` is **permanent and append-only by definition — it is the disposition base case** (the axiom that terminates the recursion). It is never itself subject to a disposition move, and **no self-referential archive-log row is ever written for it**. Its Vital status is asserted as an axiom, not derived from the classification test (the classification test applies to records the log *tracks*, not to the log itself).

## Authenticity Markers

ISO 15489-1 requires a record be **authentic** (is what it purports to be), **reliable** (trustworthy content), have **integrity** (complete + unaltered), and be **usable** (locatable + interpretable). Each characteristic is evidenced using a field the platform **already carries** — minting a new authenticity field would duplicate existing carriers (duplicate-source-discipline §1).

| ISO characteristic | Evidenced by (existing field / mechanism) | Source of truth |
|---|---|---|
| **Authentic** (who created it, when, in what process) | `source_inputs` (Category 3 provenance — the upstream human evidence) + git authorship/commit metadata for tracked records | frontmatter-schema § Category 3; git history |
| **Reliable** (trust level of the content) | `trust_category` (Category 5: `evidence` / `controlled-truth` / `interpretation` / `working-context` / `historical-record`) | frontmatter-schema § Category 5 |
| **Integrity** (unaltered / change-controlled) | git commit hash for tracked records (tamper-evident chain); `lifecycle_state` + `approval_state` for content-maturity; the least-destructive-disposition + redaction-tracking rule (§ Disposition Rules) for the disposition surface | git; frontmatter-schema § Category 2 |
| **Usability** (locatable, interpretable) | the governed-home placement (the CLAUDE.md governance map) + the README-per-folder convention + frontmatter | OPERATIONS.md § README-Per-Folder; CLAUDE.md |

**Disambiguation note (prevents a known field collision).** The record-maturity carriers are `lifecycle_state` and `approval_state`. The lexically-similar `review_status` field is the **template-protocol lifecycle field** (`core/standards/template-protocol.md` §3, the enum `DRAFT / REVIEWED / APPROVED / PROMOTED / ARCHIVED`) — it governs **template** maturity, NOT record maturity, and is **absent from `frontmatter-schema.md`**. This policy must **not** reference `review_status` as if it were a record-frontmatter field.

## Composition Boundaries

This policy is the classification + retention + disposition + authenticity **contract**; it owns no mechanism an existing protocol already owns. It composes by reference with:

- **`artifact-workflow-protocol.md` §4** — owns the `08-Generated/` 10-business-day Auto-Archive sweep mechanism (`promotion_state: staged → archived-in-place`). This policy classifies the swept artifacts (Transient) and records the retention semantic; it does not restate the sweep.
- **`lifecycle-states-canonical.md` §3.2** — owns the content-maturity / promotion-location field definitions (`lifecycle_state`, `promotion_state`). This policy reads those fields to derive class; it does not redefine them.
- **`km-governance-framework.md` §6.2** — owns the KM-retirement protocol (retirement is a `lifecycle_state: archived` content event, not a delete). This policy's destruction stance composes with that; §4.3 is the home of the out-of-scope file-deletion decision-class.
- **`projects/Archive/`** — the closed-projects archive location (Layer 2). This policy names it as the disposition location; `project-initiator` Closure mode owns the move.

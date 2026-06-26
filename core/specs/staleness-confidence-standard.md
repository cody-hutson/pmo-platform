<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
<!-- The #413 references below are the load-bearing boundary statement this standard is required to carry (it bounds the confidence-REPRESENTATION axis against the response-POSTURE axis owned by reconcile-dont-annotate.md, whose origin issue is #413). The marker covers those in-prose boundary references, which sit outside a recognized reference block by design — the boundary statement reads naturally in context, not relegated to a footnote. -->
# Staleness-Confidence Standard

## Purpose

Defines the **one** shared representation of staleness-confidence for the platform's ticket-facing staleness-detection mechanisms: a four-band ordinal **depth** scale, optionally backed by a projected continuous score. This is the single canonical home for the scale — every mechanism that reports "how confident are we that this signal is stale, and how deeply" maps its own states onto these bands, so an operator reads one vocabulary instead of five.

This standard governs the **confidence-representation axis only**. It is bounded — strictly — away from two adjacent axes:

- **Detection triggers** (*when* a mechanism fires) are owned by each mechanism's own spec. This standard never changes when a detector fires.
- **Response posture** (*what an agent does* once a signal is classified) is owned by [`reconcile-dont-annotate.md`](../disciplines/reconcile-dont-annotate.md). See § Boundary with #413.

The decision rationale (why an ordinal depth scale and not the existing time-decay score) is recorded in [ADR-043](../ADRs/ADR-043-staleness-confidence-canonical-representation.md).

## The canonical scale — four ordinal depth bands

The scale is ordered (`S0 < S1 < S2 < S3`) with stable identifiers. Each band names a **depth of staleness** — what *kind* of problem the signal indicates — and carries a state description (not an instruction; the action is the posture layer's to choose, per § Boundary with #413).

| Band | Identifier | Depth semantic (what the signal indicates) | State description |
|---|---|---|---|
| 0 | **`S0-NONE`** | No drift detected; the signal is current / verified against source. | Current and verified; nothing stale. |
| 1 | **`S1-SUPERFICIAL`** | Cosmetic / mechanically-reconcilable drift — a stale path token, a version-number reference, a renamed link. The underlying premise still holds. | Premise intact; drift is local and mechanically reconcilable. |
| 2 | **`S2-SUBSTANTIVE`** | The content's currency is in question — a value, count, date, or status the artifact asserts may no longer match source. Resolving it needs verification, not just a token swap. | Currency in question; the assertion may no longer match source. |
| 3 | **`S3-STRUCTURAL`** | Structural rot — the premise is gone, files relocated, the rule the artifact asserts no longer maps to current platform shape. Not locally reconcilable. | Premise-level problem; the asserted rule no longer maps to current shape. |

**Why four bands (not three, not five).** Four is the minimum that gives every current mechanism a lossless landing zone: each needs a distinct "no drift" zero-state (S0) and a distinct top "structural" state (S3) that the existing 3-valued shapes collapse. Five-plus would over-resolve — no current mechanism distinguishes more than four depth-relevant states, so a fifth band would be unreachable by every projector today (an empty band is a named gap, not expressiveness). This minimality claim is auditable against the per-mechanism distinct-depth-state count in the table below; it is a **re-check trigger** — if a new staleness mechanism that distinguishes more than four depth-relevant states is ever added, re-evaluate the band count at that time.

### Per-mechanism distinct-depth-state count (auditable basis for "four is sufficient and minimal")

| Mechanism | Distinct depth-relevant source states | Max band reached |
|---|---|---|
| Binary currency check (AC-Drift) | 2 (finding / no finding) | S2 (single band; see § Binary projection) |
| 3-tier context-drift severity | 3 (Low / Moderate / Critical) + no-drift | S3 |
| 3-class mid-pipeline drift verdict | 3 drift verdicts + MET | S3 |
| Typed taxonomy PT-1..PT-4 | 1 depth state (all four are S3 causes) | S3 |
| Weighted time-decay score | rule-based (continuous → cut-points) | S3 |
| Age-threshold backlog-aging | banded age (>14d / >30 / >60 / >90) | S2 (age alone never reaches S3) |

No mechanism exceeds four distinct depth-relevant states. The scale is sufficient (every state lands) and minimal (no band is unreachable).

## Score projection — a continuous score is a projection onto the scale, never the scale itself

A mechanism that already computes a continuous score may carry it **in addition** to its band, and defines a documented score→band projection rule. Today exactly one mechanism has a score: health-check **Check 2** (Staleness Scoring), whose weighted time-decay formula lives at [`core/schemas/sqlite-index-schema.md`](../schemas/sqlite-index-schema.md) (the `staleness_score` query) and whose domain thresholds (Domain A > 30, Domain B > 14, Domain C > 14) are defined there and summarized in [`health-check-specification.md`](health-check-specification.md) Check 2.

**The formula is cited, not redefined.** It stays owned by its source spec (a time-decay metric: every term is a "days since X" delta). This standard adds only the band cut-points. The score measures recency-magnitude; the bands measure depth — so the projection is deliberately conservative about the top band:

| Score condition (relative to the mechanism's own domain threshold) | Projects to |
|---|---|
| below the domain threshold | **S0-NONE** |
| ≥ threshold and < 2× threshold | **S1-SUPERFICIAL** |
| ≥ 2× threshold, **or** a Domain-C "source modified since synthesis / stale-not-flagged" condition is present | **S2-SUBSTANTIVE** |
| a contradiction-detection finding fires (published synthesis contradicts current source — the health-check Stale-Reference / contradiction check) | **S3-STRUCTURAL** |

The score reaches **S3 only via a contradiction finding**, never via a high time-decay value alone — a 200-day-stale file with one dead path token must not outrank a 3-day-stale file whose premise is gone. The 2×-threshold cut-point is a reasoned default (MEDIUM confidence) and is calibratable; the band identifiers and the "score-never-implies-S3-alone" rule are HIGH-confidence.

## Cross-mechanism mapping table

Every current ticket-facing representation projects onto the bands here. The projection is a **total function of the source signal** for discrete mechanisms (each source state → exactly one band, no second judgment required) and **rule-based** (cut-points) for the one score. The mapping lives once, here; consumers reference it and never duplicate it.

| # | Mechanism (source representation) | Source surface | Source states | Projection onto S0..S3 |
|---|---|---|---|---|
| 1 | **Binary — AC-Drift currency check** | [`release/governance/release-process.md`](../../release/governance/release-process.md) § AC-Drift Handling Protocol | `CURRENCY-MISMATCH` / (no finding) | no finding → **S0-NONE**; `CURRENCY-MISMATCH` → **S2-SUBSTANTIVE** (currency in question). The binary maps to a **single** band; escalation to S3-STRUCTURAL when the AC's premise itself is invalid is a **posture-layer** decision (the existing Tier-2 [SCOPE CHANGE] route), not a second representation-side judgment. See § Binary projection. |
| 2 | **3-tier severity — context-drift** | [`core/CLAUDE.md.template`](../CLAUDE.md.template) § Context drift detection | Low / Moderate / Critical (+ no drift) | (no drift) → **S0-NONE**; Low (formatting, word choice) → **S1-SUPERFICIAL**; Moderate (stale dates, outdated summaries) → **S2-SUBSTANTIVE**; Critical (wrong file counts, missing files, governance file moved/deleted) → **S3-STRUCTURAL**. |
| 3 | **3-class verdict — mid-pipeline AC drift verdict** | [`release/governance/release-process.md`](../../release/governance/release-process.md) § QA-side drift-verdict enum | `MET` / `REINTERPRET-WITH-RATIONALE` / `N/A-WITH-RATIONALE` / `FLAG-UPSTREAM` | `MET` → **S0-NONE**; `REINTERPRET-WITH-RATIONALE` (1:1 re-map, criterion still MET) → **S1-SUPERFICIAL**; `N/A-WITH-RATIONALE` (premise stale, intent met by an equivalent signal) → **S2-SUBSTANTIVE**; `FLAG-UPSTREAM` (cannot evaluate / premise structurally invalid) → **S3-STRUCTURAL**. The satisfaction-axis verdicts (`NOT MET` / `PARTIAL`) are a different axis (AC-satisfaction, not staleness-depth) and are **not** mapped here. |
| 4 | **Typed taxonomy — Tier 0 PT-1..PT-4** | [`release/governance/release-process.md`](../../release/governance/release-process.md) § Tier 0 — Premise Rejection + [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) | PT-1 stale-assumption / PT-2 subsumption / PT-3 best-practices-conflict / PT-4 learnings-contradiction | All four → **S3-STRUCTURAL**. Tier 0 fires only on a C3 ("should be challenged") premise-level finding, so every PT is structural by definition. **PT-1..PT-4 is a *cause* dimension orthogonal to the depth scale** — it sub-classifies *why* an S3 exists; it does not span S0..S2 and is never re-binned across the bands. Carry it as an orthogonal cause tag on S3. |
| 5 | **Weighted graduated score — health-check Check 2** | [`health-check-specification.md`](health-check-specification.md) Check 2 (formula at [`sqlite-index-schema.md`](../schemas/sqlite-index-schema.md)) | continuous `staleness_score` (unbounded float) with domain thresholds | Rule-based — see § Score projection (below threshold → S0; ≥ threshold & < 2× → S1; ≥ 2× or Domain-C stale-not-flagged → S2; contradiction finding → S3). The only rule-based row; the formula is cited, not redefined. |
| 6 | **Age-threshold binary — backlog-aging** | [`operations/skills/delivery-engine/SKILL.md`](../../operations/skills/delivery-engine/SKILL.md) § Aging | open >30/60/90d; same-status >14d | >14d same-status / >30d open → **S1-SUPERFICIAL** (aging signal, premise intact); >60d → **S2-SUBSTANTIVE**; >90d → **S2-SUBSTANTIVE** with an escalation flag. **Age alone never implies S3** — structural depth requires a premise/path finding, not elapsed time. |

Rows 4 and 5 carry the two non-obvious calls: the PT taxonomy is a cause axis that lives entirely at S3 (not a depth span), and the score is the only rule-based projection while every discrete mechanism is enumerated.

## Binary projection — single band, posture-layer escalation

A two-state (binary) mechanism, or a bare elapsed-time signal, maps to a **single band that its own signal determines** — the projection must be reproducible from the signal alone, with no second classification pushed onto the reader. Concretely: AC-Drift's `CURRENCY-MISMATCH` lands on **S2-SUBSTANTIVE** ("currency in question"), and an audit-snapshot unverified outcome lands on **S2-SUBSTANTIVE**, full stop.

Escalation to **S3-STRUCTURAL** — when the premise itself is invalid (a named premise artifact 404s, a governance file moved, the rule no longer maps) — is a **posture-layer move**, made by the response discipline ([`reconcile-dont-annotate.md`](../disciplines/reconcile-dont-annotate.md)) when *its* premise-rejection test fires, not a band the bare binary self-reports. This keeps the representation lossless and deterministic (a binary never needs an unstated "is the premise invalid?" judgment to pick its band) and keeps the depth scale honest (the same principle that caps backlog-aging at S2 — *structural requires a premise finding, not the bare signal* — generalizes to every binary).

## Boundary with #413 (reconcile-don't-annotate)

This standard governs the **representation** of staleness-confidence — the shared scale a detector uses to report how stale, and how deeply, a signal is. It does **not** govern the **response posture** — what an agent does once a signal is classified (reconcile in place vs. annotate vs. escalate vs. defer). Response posture is owned by [`reconcile-dont-annotate.md`](../disciplines/reconcile-dont-annotate.md). The two compose: a detector emits a band on this scale (representation); the reconcile-don't-annotate decision consumes the band to choose the response (posture). An `S1-SUPERFICIAL` signal composes with "reconcile in place"; an `S3-STRUCTURAL` signal composes with "in-body authoritative reconciliation or file a follow-up" — but that mapping is reconcile-don't-annotate's to make, not this standard's. **This standard defines the band; it never prescribes the action.**

## Evidence-Grounding (per R1)

This standard canonicalizes one convention: the shared four-band staleness-confidence depth scale. Grounding follows [`evidence-grounding-standard.md`](../standards/evidence-grounding-standard.md).

#### Canonicalization: the shared staleness-confidence depth scale (S0..S3)

**Current-state enumeration** (the five divergent representations being unified, plus the named backlog-aging consumer):

| Source | Variant observed | Distinct depth states | Reproducible command |
|---|---|---|---|
| `release/governance/release-process.md` § AC-Drift Handling Protocol | Binary (`CURRENCY-MISMATCH` / none) | 2 | `grep -n "CURRENCY-MISMATCH" release/governance/release-process.md` |
| `core/CLAUDE.md.template` § Context drift detection | 3-tier severity (Critical / Moderate / Low) | 3 | `grep -n "Context drift detection" core/CLAUDE.md.template` |
| `release/governance/release-process.md` § QA-side drift-verdict enum | 3-class verdict (N/A / REINTERPRET / FLAG-UPSTREAM) + MET | 3 (+MET) | `grep -n "N/A-WITH-RATIONALE\|REINTERPRET-WITH-RATIONALE\|FLAG-UPSTREAM" release/governance/release-process.md` |
| `release/references/standards/triage-design-rereview.md` | Typed taxonomy (PT-1..PT-4) | 1 (all S3 causes) | `grep -n "PT-1\|PT-2\|PT-3\|PT-4" release/references/standards/triage-design-rereview.md` |
| `core/specs/health-check-specification.md` Check 2 (formula `core/schemas/sqlite-index-schema.md`) | Weighted graduated score (unbounded float) | continuous | `grep -n "Check 2: Staleness Scoring" core/specs/health-check-specification.md; grep -n "staleness_score" core/schemas/sqlite-index-schema.md` |
| `operations/skills/delivery-engine/SKILL.md` § Aging | Age-threshold (>30/60/90; same-status >14) | banded | `grep -n "Aging.*tickets open" operations/skills/delivery-engine/SKILL.md` |

**Survey command (prior-canonicalization check):** `grep -rlE 'staleness-confidence|confidence-representation|unified.*staleness' core/specs/ core/standards/ core/disciplines/` returned no prior canonical scale at survey time — confirming this is the first canonicalization, with nothing to reconcile against.

**Canonical choice:** `core/specs/staleness-confidence-standard.md`, defining the four-band ordinal scale S0-NONE / S1-SUPERFICIAL / S2-SUBSTANTIVE / S3-STRUCTURAL, a cross-mechanism mapping table (≥5 rows), and a score-projection rule for the one score-bearing mechanism.

**Canonical-choice justification** (placement + naming):

- **Audit finding:** the originating task's verify-before-recommend pass established all five mechanisms live, divergent, and with no existing unification — the empirical basis for "unify."
- **Upstream convention (placement):** `core/specs/` holds the platform's cross-mechanism reference specs and rule/vocabulary standards — e.g. [`reversibility-protocol.md`](reversibility-protocol.md), [`label-taxonomy.md`](label-taxonomy.md), [`autonomy-tiers.md`](autonomy-tiers.md), and [`health-check-specification.md`](health-check-specification.md) (which owns the one score this standard projects). A cross-mechanism representational standard that other mechanisms conform to is the same class. The originating task's completion condition also names `core/specs/` as the required location explicitly. (Naming is kebab-case with the `-standard.md` suffix, matching the directory's convention.)
- **Upstream convention (severity-band idiom):** ordinal-severity-with-named-bands is the platform's own established pattern for depth/severity — the existing 3-tier context-drift severity in `core/CLAUDE.md.template` and the failure-mode severity enum. The four-band scale generalizes that existing idiom rather than inventing a foreign shape.
- **Documented rationale (ADR):** [ADR-043](../ADRs/ADR-043-staleness-confidence-canonical-representation.md) records the score-vs-ordinal-vs-hybrid decision and the reversal of the originating task's lean toward generalizing the time-decay score wholesale.

**Out-of-scope drift detected during survey:**

- The QA-side drift-verdict enum is **6-valued** (MET / NOT MET / PARTIAL / N/A-WITH-RATIONALE / REINTERPRET-WITH-RATIONALE / FLAG-UPSTREAM); only the three drift verdicts (+ MET) are staleness-depth states. The other two (NOT MET / PARTIAL) are AC-satisfaction states on a different axis. Mapping-table Row 3 maps only the staleness subset and must not collapse the satisfaction axis into the depth axis. — **Routing: accepted-residual** (the enum is correctly multi-purpose).
- Check 2's domain thresholds (A > 30, B > 14, C > 14) are *time-decay* thresholds, not depth thresholds; the score-projection rule derives band cut-points *relative to* them (below / ≥ / ≥ 2×) rather than treating threshold-crossing as S3. — **Routing: in-scope** (handled by § Score projection; called out so a threshold crossing is never naively equated with structural depth).

## Cross-references

- [ADR-043](../ADRs/ADR-043-staleness-confidence-canonical-representation.md) — the decision record for this standard.
- [`reconcile-dont-annotate.md`](../disciplines/reconcile-dont-annotate.md) — the response-posture discipline this standard composes with (the band feeds its decision tree). See § Boundary with #413.
- [`health-check-specification.md`](health-check-specification.md) Check 2 + [`sqlite-index-schema.md`](../schemas/sqlite-index-schema.md) — owner of the one score this standard projects (the formula is cited, not redefined).

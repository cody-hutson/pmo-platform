---
title: KM Scanning — PMO QA Auditor Mode E Reference
purpose: The reference for pmo-qa-auditor Mode E (knowledge-management scanning) — how the auditor scans an output for KM signals and codification candidates.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# KM Scanning — PMO QA Auditor Mode E Reference

## Purpose

This file is the full specification for the **Knowledge-Management (KM) check-set** that
`pmo-qa-auditor` **Mode E — Platform Health Audit** runs as one numbered step of its process
(inserted between the D1–D8 detector battery and the audit-folder emit). The check-set runs
**four mechanical scans** over the K1 corpus and emits **two new observational artifacts** into
the existing Mode E audit folder — a **doc-debt register** and a **staleness report ranked by
criticality** — plus a **KM In-Flight Capture** subsection folded into `findings-register.md`.

It is **not a new mode**. It is the same observational corpus-health output class as the
base-vs-build drift audit and the D1–D8 detector battery, so it lives in Mode E (the lone
producer mode) and inherits Mode E's audit-class observational discipline.

**This file redefines nothing.** Every threshold, formula, weight, band, state, and timing rule
is **consumed** from its canonical upstream and **cited** here — the doc-debt model and the
staleness model are owned by `km-protocols.md`; the `KM-<State>` naming convention is owned by
`lifecycle-states-canonical.md`; the K1-tier population is owned by `knowledge-architecture.md`.
This consumer ships those models **demonstrated**; the upstreams ship them **specified**
(`km-protocols.md` §5 names "QA Auditor KM scanning" as exactly this consumer).

**Authoritative cross-references (CITE, never redefine):**
- [`../../../disciplines/km-protocols.md`](../../../disciplines/km-protocols.md) — **§1** KM-artifact lifecycle states/transitions; **§2** two-key staleness-by-criticality model + the `staleness_due(a)` rule; **§5** the `doc_debt(a)` formula, the five mechanical inputs, the priority bands; **§6** the in-flight capture-timing decision table. This check-set is the §5/§2/§6 consumer.
- [`../../../standards/lifecycle-states-canonical.md`](../../../standards/lifecycle-states-canonical.md) — **§4.4** the `KM-` object-prefix registration and the `KM-<State>` naming convention used on both output artifacts' `Lifecycle` column. (`km-protocols.md` §1 is the authoritative state-definition home; this doc cites the convention only.)
- [`../../../disciplines/knowledge-architecture.md`](../../../disciplines/knowledge-architecture.md) — the K1-codified corpus definition (the scan population) and the Q1/Q2 tier classifier (the upstream owner of K-tier).

---

## §1 Scan scope (the artifact population)

The scan population is the **K1 codified corpus** per
[`knowledge-architecture.md#k1-codified`](../../../disciplines/knowledge-architecture.md#k1-codified):
`core/**/*.md` + `release/**/*.md` durable-corpus docs that carry frontmatter from which a K-tier
is resolvable (an ADR, a promoted lessons-learned entry, a codified-practice doc, or a `core/`
corpus doc — the KM-artifact definition per `km-protocols.md` §scope).

**Exclusions (a KM artifact is K1 only — `km-protocols.md` §scope):**
- K2–K5 contextual knowledge — not a KM artifact in this sense; it routes to its tier-specific
  placement home and is never governed by the §1 lifecycle, so it is out of population.
- Operator-instance / git-ignored paths (the audit folder itself, operator roadmaps, local
  analysis) — not tracked corpus.
- Fenced historical snapshots / archived content explicitly marked non-authoritative.

**Baseline-pin discipline (per CLAUDE.md "Audit-baseline discipline"):** the scan records the
**scan SHA + a bounded window** in each artifact's header. The population is **re-checked before
findings are relied upon** — a default-to-clean classification on a transiently-empty population
is not load-bearing on its own. The scan SHA + date appear in both output headers.

---

## §2 Input derivation (all mechanical)

Every input below derives from frontmatter + `grep`/dependency-graph fan-out + the existing
`check-doc-links.py` primitive — **no model judgment enters the score.** The only judgment is the
**upstream** K-tier classifier and the **upstream** ET admission, neither re-litigated here. Each
row names the **owning section** and the **derivation command/field**; **no threshold value is
restated** — only how the input is computed.

### §2.1 The five doc-debt inputs (per `km-protocols.md` §5)

| Input | What it is | Derivation (mechanical) | Owning section |
|---|---|---|---|
| `S(a)` Staleness | {0,1,2,3} | `0` within `staleness_due`; `1` = 0–25% past; `2` = 25–100% past; `3` = >100% past — bands per §5; `staleness_due` itself per §2 | `km-protocols.md` §5 (bands) + §2 (`staleness_due`) |
| `C(a)` Criticality | {1,2,3} | inbound-cross-ref count via `grep` / dependency-graph fan-out (the same fan-out `blast-radius.sh` uses): K1 with ≥3 inbound = 3; 1–2 = 2; K3/K5 or uncited = 1 | `km-protocols.md` §5 |
| `E(a)` Evidence-gap | {0,1,2} | K1 corpus only, keyed on the artifact's ET tier (cite `corpus-curation.md#evidence-tier-vocabulary`); non-K1 = 0 | `km-protocols.md` §5 |
| `L(a)` Bus-factor | {0,1} | `1` iff §4 marks the artifact bus-factor-critical (frontmatter + `grep` — K5/K3 AND no K1 externalization); else `0` | `km-protocols.md` §5 / §4 |
| `B(a)` Broken-refs | int ≥ 0 (capped at 3 in the formula) | count of unresolved outbound links via the existing `check-doc-links.py` primitive — reuse, do not reinvent | `km-protocols.md` §5 |

The **formula** `doc_debt(a) = 3·S(a) + 2·C(a) + 2·E(a) + 2·L(a) + 1·min(B(a),3)`, its
**weights**, its **range 0–24**, and the **P1/P2/P3 bands** are all `km-protocols.md` §5 — applied
verbatim, never restated as new values here. The register column `doc_debt` renders the §5 sum;
the `Band` column renders the §5 band table.

### §2.2 The staleness keys (per `km-protocols.md` §2)

`staleness_due(a) = published_date(a) + threshold(K_tier(a), ET_tier(a))` — the §2 computable rule.
**Primary key** = K-tier Mutability (decided by the upstream `knowledge-architecture.md` Q1/Q2
classifier); **secondary key** (K1 corpus only) = ET tier (decided by the upstream corpus-curation
admission rubric). The threshold table is `km-protocols.md` §2 — **consumed, never redefined**. An
artifact is **stale** iff `today > staleness_due(a)` OR a §2 event trigger fires (the
corpus-curation step-6 RT-a..RT-d retirement triggers, which compose with the date test).

### §2.3 Lifecycle-state read (per `km-protocols.md` §1 + `lifecycle-states-canonical.md` §4.4)

Read each KM artifact's lifecycle state (`KM-Proposed / KM-Active / KM-Deprecated /
KM-Superseded / KM-Rejected`) from its frontmatter / governing record. **Surface** artifacts whose
state is **terminal** (`KM-Deprecated` / `KM-Superseded` / `KM-Rejected` — the §1 terminal set) or
that are **stale-while-`KM-Active`** (a live authoritative doc past its `staleness_due`). The
object-prefix form `KM-<State>` is used on the register/report `Lifecycle` column per
`lifecycle-states-canonical.md` §2.1/§4.4; the state semantics are `km-protocols.md` §1.

### §2.4 In-flight predicate (per `km-protocols.md` §6)

Apply the §6 capture-timing decision table to the audit window: flag any decision with
reversibility **EXPENSIVE / IRREVERSIBLE**, any operator correction revealing **class-potential**,
or any **non-obvious-constraint workaround** observed in the window that has **no corresponding
`KM-Proposed` capture** (no in-session ADR / observation-log entry / point-of-use record). The §6
table owns the trigger→timing mapping; this check applies it.

---

## §3 Output 1 — doc-debt register (`km-doc-debt-register.md`)

One row per scanned K1 artifact with `doc_debt(a) > 0`. Clean artifacts (`doc_debt = 0`) are
**summarized in a count line**, not enumerated. Sort: `doc_debt` **descending**.

| Column | Source / derivation | Notes |
|---|---|---|
| `Artifact` | file path | the scanned K1 doc |
| `K-tier` | frontmatter `K-tier` (or upstream Q1/Q2 classifier) | INDETERMINATE if unresolved (§5) |
| `Lifecycle` | `KM-<State>` per `km-protocols.md` §1 / `lifecycle-states-canonical.md` §4.4 | terminal states flagged |
| `S` | staleness input {0,1,2,3} per §5 §2.1 | mechanical |
| `C` | criticality {1,2,3} per §5 (inbound-ref count) | `grep`/dep-graph fan-out |
| `E` | evidence-gap {0,1,2} per §5 (ET tier; K1 only) | non-K1 = 0 |
| `L` | bus-factor {0,1} per §5 / §4 | frontmatter + `grep` |
| `B` | broken-refs `min(count,3)` per §5 via `check-doc-links.py` | capped at 3 in the sum |
| `doc_debt` | `3S + 2C + 2E + 2L + 1·min(B,3)` — range 0–24 | the §5 formula, verbatim |
| `Band` | P1 / P2 / P3 per the §5 band table | **observed** disposition; operator renders |

**Header** records: scan SHA + audit date + population count + INDETERMINATE count.
**Closing line** (observational — no prescriptive verb): "Bands are observed dispositions per
`km-protocols.md` §5; the operator renders the route (QC4-05 A/B/C)."

---

## §4 Output 2 — staleness report (`km-staleness-report.md`)

One row per artifact flagged **stale** OR **within 25% of due** (DUE-SOON), **ranked by
criticality** (the ranking key the staleness report requires). Sort: `Criticality rank` **descending**, then
`staleness_due` **ascending** (most-overdue-most-critical first).

| Column | Source / derivation | Notes |
|---|---|---|
| `Artifact` | file path | |
| `K-tier (Mutability)` | frontmatter / classifier | the §2 primary key |
| `ET-tier` | corpus-curation admission (K1 only) | the §2 secondary key |
| `published_date` | frontmatter | INDETERMINATE if absent (§5) |
| `staleness_due` | `published_date + threshold(K_tier, ET_tier)` per §2 | the §2 computable rule |
| `Status` | `STALE` (today > due) / `DUE-SOON` (within 25%) / `EVENT-TRIGGERED` (a §2 RT-a..RT-d trigger fired) | §2 + §5 `S(a)` bands |
| `Criticality rank` | `C(a)` from §5 (3 = K1 w/ ≥3 inbound; 2 = 1–2; 1 = K3/K5/uncited) | the **ranking key** |

**Header** records: the §2 threshold table is consumed-not-redefined, plus scan SHA + audit date.

---

## §5 INDETERMINATE posture

Any artifact whose **K-tier**, **ET-tier** (when K1), **`published_date`**, or **lifecycle state**
is **unresolvable** is **never silently treated as clean**. It appears as a row with the affected
field(s) marked `INDETERMINATE` and the **specific missing field named** — mirroring the D1–D8
detector-battery INDETERMINATE posture (a detector whose required input cannot be resolved reports
INDETERMINATE with the missing input named, never silently clean).

Edge handling (all resolve to a *named* row, never a skip):
- `published_date` absent → `staleness_due` = INDETERMINATE; the staleness report row names the
  missing field. `S(a)` cannot be computed → the doc-debt row carries `S = INDETERMINATE`.
- `B(a)` uncomputable (the `check-doc-links.py` primitive not invokable in the run context) →
  `B = INDETERMINATE` for that artifact (fall back to INDETERMINATE-for-B, do not assume 0).
- ET-tier unset on a non-curated doc → `E(a) = 0` for non-K1 per §5; INDETERMINATE **only** when
  the doc is K1 **and** ET is unresolved.

The header INDETERMINATE count makes the unresolved population auditable rather than absorbed.

---

## §6 Mode E integration point

The KM check-set runs as the numbered Mode E step inserted **between the D1–D8 detector battery
and the audit-folder emit** (the SKILL.md Mode E `## Process` carries it as step 5.5). Its outputs
land **inside the existing Mode E audit folder** at
`<OPERATOR_INSTANCE_ANALYSIS_PATH>/platform-health-${AUDIT_DATE_UTC}/` (operator-instance,
git-ignored — the same folder Mode E already emits); **no change to the four existing files'
schemas.**

| Emitted artifact | Where | Schema |
|---|---|---|
| `km-doc-debt-register.md` | new file in the audit folder | §3 above |
| `km-staleness-report.md` | new file in the audit folder | §4 above |
| `## KM In-Flight Capture` | a **subsection appended to `findings-register.md`** (NOT a separate file — keeps the folder lean) | §2.4 predicate output |

**In-flight subsection contract:** lists any EXPENSIVE/IRREVERSIBLE decision or class-potential
correction observed in the audit window with **no corresponding `KM-Proposed` capture**, each with
the §6 trigger row it matched. **Observational**; an empty section reports "no uncaptured in-flight
knowledge observed this window" (**present-but-empty, never omitted** — mirrors the Evidence-
Grounding drift-section discipline).

**In-chat echo:** Mode E adds one **KM-scan status line** to its SUMMARY echo (alongside the
detector-battery status line) — the doc-debt band counts (P1/P2/P3) + the stale-artifact count +
a pointer to the two KM artifacts in the audit folder. No prescriptive verbs — the line describes
observed state, not action.

**Observational-discipline inheritance:** all KM-scan output is bound by the Mode E step-7
observational self-check — no prescriptive verbs (`recommend` / `migrate` / `consolidate` /
`should`). The doc-debt **bands** are stated as *observed* dispositions the operator renders
(mirroring how `km-protocols.md` §5 frames them — "Disposition (operator renders)").

---

## §7 Domain-Specific Failure Modes

These domain-specific anti-patterns govern the KM check-set itself. Each entry uses the 5-field
conditional template per [`../../../standards/failure-mode-standard.md`](../../../standards/failure-mode-standard.md)
and carries one of the five category tags (TRIG / INPUT / PROC / OUT / HAND).

### Staleness threshold restated locally instead of consumed from km-protocols §2 — PROC

- **Signature (observable signal):** the KM check-set computes `staleness_due` or a doc-debt
  input using an age, weight, band boundary, or ET refinement written **into this scan** (a
  hardcoded "36 mo", a re-derived `3·S + 2·C …` with a changed coefficient, a P1 boundary other
  than the §5 value) rather than reading the value from `km-protocols.md` §2/§5.
- **Conditional:** do NOT restate any staleness threshold, doc-debt weight, range, or band
  boundary inside the KM scan when `km-protocols.md` §2/§5 owns it, because a second copy of a
  tunable constant drifts the moment the upstream is tuned — and the design contract is explicit
  that this consumer ships the model **demonstrated** while km-protocols ships it **specified**
  (one home for the number, per `duplicate-source-discipline.md`).
- **Root cause:** inlining the constant feels faster and self-contained — the scan reads as
  complete without a cross-doc lookup, and a literal "36 mo" in the code looks more concrete than
  a citation. The cost (silent divergence after an upstream tune) is deferred and invisible at
  authoring time.
- **Mitigation:** every input derivation cites its owning § (§2 for thresholds, §5 for weights/
  bands); the scan reads the value at run time from the upstream, never embeds it; the output
  headers state "thresholds consumed from `km-protocols.md` §2/§5, not redefined"; a reviewer
  greps the scan for bare ages/coefficients and routes any literal to a citation.
- **Principal response vs. junior response:** Principal cites §2/§5 and renders the band from the
  upstream table, so an upstream re-tune propagates for free. Junior hardcodes "P1 ≥ 16" into the
  scan, the upstream later moves the boundary, and the register silently mis-bands every artifact
  until someone notices the two homes disagree.

### Unresolvable K-tier/published_date silently scored as clean — INPUT

- **Signature (observable signal):** a KM artifact with a missing or unparseable `K-tier`,
  `published_date`, ET-tier (when K1), or lifecycle state is **omitted from the register/report**
  or assigned `doc_debt = 0` / `Status = current` — with no INDETERMINATE row and no named missing
  field, so the artifact reads as healthy when it was in fact unscored.
- **Conditional:** do NOT assign a clean score (or drop the row) when a required input is
  unresolvable, because absence-of-signal is not evidence-of-health — a doc with no
  `published_date` is *unscanned*, not *current* — and treating unscanned as clean is the exact
  echo-chamber failure the detector-battery INDETERMINATE posture exists to prevent (the scan
  would certify health it never measured).
- **Root cause:** a missing field produces no positive debt signal, so the artifact falls through
  to the `doc_debt = 0` default and is summarized into the clean count; the gap is invisible
  precisely because nothing flagged it. Enumerating INDETERMINATE rows also enlarges the output,
  which tempts collapsing them.
- **Mitigation:** any unresolvable input yields an explicit row with the field marked
  `INDETERMINATE` and the missing field named (§5 posture); the header carries an INDETERMINATE
  count; `B(a)` falls back to INDETERMINATE-for-B when the link primitive is unavailable rather
  than to 0; the clean-count line counts only artifacts with **all** inputs resolved to a value.
- **Principal response vs. junior response:** Principal emits the INDETERMINATE row, names the
  missing `published_date`, and the operator sees an unscanned doc to fix. Junior lets the doc
  inherit `doc_debt = 0`, it joins the clean count, and a stale critical artifact hides inside a
  green summary.

### Prescriptive verb leaks into the doc-debt register or staleness report — OUT

- **Signature (observable signal):** a KM-scan artifact (`km-doc-debt-register.md`,
  `km-staleness-report.md`, or the `## KM In-Flight Capture` subsection) contains a prescriptive
  verb — `recommend`, `migrate`, `consolidate`, `should`, "must retire", "action: update" — in a
  band disposition, a closing line, or a finding, rather than an observed-state statement.
- **Conditional:** do NOT emit a prescriptive verb in any KM-scan output when the artifact is a
  Mode E observational product, because Mode E inherits the audit-class observational discipline
  (`review-discipline-principles.md`) — the scan **observes** corpus health and the **operator**
  renders the route (the §5 bands are explicitly "Disposition (operator renders)") — and a scan
  that tells the operator what to do has crossed from observation into a decision it has no
  authority to make.
- **Root cause:** a P1 band reads as urgent, so the natural next sentence is an instruction; the
  observational framing feels incomplete without a "so do X". The pull toward action-language is
  strongest exactly where the debt is highest.
- **Mitigation:** run the Mode E step-7 observational self-check over the two KM artifacts plus
  the in-flight subsection before emit; rewrite any prescriptive verb to observed-state form
  ("Band: P1 — observed" not "P1 — migrate now"); the closing line states the operator renders
  the QC4-05 route; the empty in-flight section uses the present-but-empty observed-state phrasing.
- **Principal response vs. junior response:** Principal writes "doc_debt = 18 (P1, observed);
  operator renders route per §5" and the audit stays observational. Junior writes "P1 — recommend
  immediate consolidation", the audit prescribes an action, and a downstream reviewer flags the
  observational-discipline breach the self-check should have caught.

---

## §8 References

| Reference | Role |
|---|---|
| [`../../../disciplines/km-protocols.md`](../../../disciplines/km-protocols.md) | §1 lifecycle states/transitions/terminal set · §2 staleness-by-criticality + `staleness_due` rule · §5 `doc_debt` formula/inputs/weights/bands · §6 in-flight capture-timing table — the owners this scan consumes |
| [`../../../standards/lifecycle-states-canonical.md`](../../../standards/lifecycle-states-canonical.md) | §4.4 `KM-` registration + §2.1 `KM-<State>` naming convention for the `Lifecycle` column |
| [`../../../disciplines/knowledge-architecture.md`](../../../disciplines/knowledge-architecture.md) | K1-codified corpus = the scan population; Q1/Q2 tier classifier = the upstream owner of K-tier |
| [`../../../disciplines/corpus-curation.md`](../../../disciplines/corpus-curation.md) | `#evidence-tier-vocabulary` (ET1–ET5) — cited via km-protocols §2/§5 for `E(a)` and the staleness secondary key; the RT-a..RT-d retirement triggers for `EVENT-TRIGGERED` status |
| [`../../../deploy/tools/check-doc-links.py`](../../../deploy/tools/check-doc-links.py) | the existing primitive that computes `B(a)` broken-outbound-link counts (reuse, do not reinvent) |
| [`../../../../release/tools/blast-radius.sh`](../../../../release/tools/blast-radius.sh) | the inbound-reference fan-out method `C(a)` reuses for the criticality count |

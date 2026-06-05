---
pack_name: generic
pack_version: "1.0"
applies_to: "Any document pack without a domain-specific pack match (default fallback)"
detection_patterns: []
default_when_no_match: true
dimension_count: 7
principal_dimensions_included: false
---

# Generic Document Pack — Dimension Pack (Default Fallback)

Baseline review dimensions for arbitrary governed document packs that do not match a domain-specific pack. This pack is the **default fallback**: it is selected only when (a) the invoker did not pass `--pack=<name>` and (b) no registered pack's `detection_patterns` matched any target path.

When this pack is loaded via fallback, the review output MUST render the following banner at the top of the findings register:

> *Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if reviews recur.*

The banner is omitted when `generic` is loaded via explicit user override (`--pack=generic`) — in that case the pack is chosen intentionally.

This pack supplies 7 baseline dimensions. The shared review discipline (anti-laziness rules, root-cause requirement, 6-deliverable output structure, reviewer calibration, anti-patterns) and the 3 Principal Dimensions are inherited from `build-reviewer/SKILL.md` and [`core/disciplines/review-discipline-principles.md`](../../../../../core/disciplines/review-discipline-principles.md).

**Severity scale:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` per `review-discipline-principles.md` § Section 5.

---

## Review Dimensions

You must evaluate the provided document pack against every dimension below. For each dimension, produce findings or provide explicit evidence-of-check per Anti-Laziness Rule #3.

### GEN-D1 — Completeness

**What to check:**
- Is the document inventory complete per a declared manifest (if one exists)? If no manifest exists, identify the implied inventory from cross-references within the pack.
- Are files referenced (from within the pack or from an external caller) but missing from the pack?
- Are files present but not referenced (orphan files)? Orphan files are not always defects, but flag when their purpose cannot be inferred.

**Root-cause requirement:** For missing files, identify whether the file was renamed, moved, deleted, or never authored. For orphan files, identify whether the file was superseded by another file or simply un-wired.

### GEN-D2 — Cross-Reference Integrity

**What to check:**
- Do internal cross-references resolve? A reference like `See X.md § Y` must point to a section that exists with that exact heading in X.md.
- Do references from outside the pack to inside the pack resolve (where identifiable)?
- Are there references that predate a rename (stale path) or predate a restructure (stale heading)?

**Root-cause requirement:** For each broken reference, distinguish stale-path (target moved or renamed) from stale-heading (target section renamed within file) from never-existed (reference points to content that was never authored).

### GEN-D3 — Schema Consistency

**What to check:**
- Where the pack declares contracts or schemas (whether JSON, YAML, markdown tables, or natural-language field lists), do producer and consumer agree on field names, types, required-ness, and value constraints?
- Are there fields declared in the schema that no consumer actually references? Are there fields that consumers reference but the schema does not declare?
- Are enum values or controlled vocabularies used consistently across producers and consumers?

**Root-cause requirement:** For each schema inconsistency, identify the authoritative source, the deviating reference, and whether the fix belongs upstream (schema needs a field) or downstream (reference needs correction).

### GEN-D4 — Assumption Control

**What to check:**
- Are assumption-bearing claims marked? Is there a quarantine or ownership mechanism for unconfirmed content?
- Are assumptions distinguished from assertions (claims backed by evidence) and recommendations (claims backed by judgment)?
- Are there places where assumption-bearing content could leak into governed logic without the quarantine controls catching it?

**Root-cause requirement:** For each leak path or enforcement gap, trace the assumption lifecycle from creation through potential escape to the point where it should have been caught.

### GEN-D5 — Intent Alignment

**What to check:**
- Do the implementation artifacts still serve the pack's stated goals? If the pack declares a charter, mission, or success criteria, does the current state deliver them?
- Has scope drifted since the original charter? Has the pack accumulated content that was not in the original plan and does not serve declared goals?
- Are there non-goals (explicit out-of-scope statements) that a document in the pack inadvertently violates?

**Root-cause requirement:** For each gap between intent and implementation, classify it as: (a) justified evolution that should be documented as a conscious decision, (b) scope creep that should be remediated, or (c) fundamental design tension that requires an explicit tradeoff acknowledgment.

### GEN-D6 — Scope Creep Detection

**What to check:**
- Are there controls, rules, or requirements in the pack that exceed its declared scope?
- Are there cross-references from inside the pack to external concerns that the pack should not own?
- Does the pack's footprint (document count, page count, cross-reference density) match its declared scope?

**Root-cause requirement:** For each creep instance, identify whether the creep is content-level (a document takes on responsibilities outside its charter) or architecture-level (the pack extends beyond its declared surface).

### GEN-D7 — Structural Coherence

**What to check:**
- Do the documents consistently follow the pack's own architecture rules (ownership, reference, anti-overlap)?
- Where the pack declares document ownership rules or anti-overlap constraints, do the documents honor them?
- Are there cases where two documents assert ownership over the same concept? Are there cases where a document restates another document's content without a subordination marker?

**Root-cause requirement:** For each coherence violation, identify which document should own the concept and which should reference it. For restatement without subordination, identify the architecture rule that was not applied.

---

## Pack-Specific Calibration Context

This pack is domain-agnostic. Calibration for a fallback review should include: (a) an explicit statement of the operator profile (who requested this review, what their decision authority is) even when the pack does not know the domain; (b) an explicit scope declaration (what the reviewer considered in-scope vs. out-of-scope given the absence of domain signal); (c) a recommendation on whether to author a domain-specific pack if reviews of this domain recur.

The fallback banner declared at the top of this file serves as the audit trail — the operator can see that the pack was used by fallback and decide whether to invest in a domain-specific pack for future reviews.

---

## Pack Start

Start with GEN-D1 (completeness) and GEN-D2 (cross-reference integrity) — failures there typically produce the most findings and establish the baseline signal for the rest of the review. After pack-specific dimensions complete, the skill's `## Principal Dimensions` section applies to every finding register regardless of pack.

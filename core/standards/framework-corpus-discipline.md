---
title: Framework Corpus Discipline Protocol
purpose: Catalog, version-anchor convention, and tiered review cadence for every named framework/methodology/standard the platform references
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: "deploy.sh --check Check 18 (the catalog-registry-driven enforcement this protocol defines — 18a/18b/18c); check-version-anchors.py (the primitive that implements the version-anchor convention); framework-catalog.md (the registry-of-record this protocol governs); OPERATIONS.md Framework Review Cadence Protocol (consumes the tiered review cadence)"
owner: Workspace owner ([OPERATOR_NAME])
adr: ""
enforcement: deploy.sh --check Check 18 (catalog-registry-driven; 18a completeness / 18b catalog↔doc consistency / 18c cadence aging)
primitive: core/deploy/tools/check-version-anchors.py
registry: core/specs/framework-catalog.md
cross_references: version-field-semantics.md (parallel anchor mechanism), doc-link-maintenance-protocol.md (warn-mode + flip-to-enforce precedent), bypass-mode-readiness.md (shakedown precedent)
---
<!-- reference-durability: allow-link -->

# Framework Corpus Discipline Protocol

**Status:** ACTIVE
**Owner:** Platform engineering — release-ops domain
**Enforcement:** Automated via `./deploy.sh --check` Check 18 (catalog-registry-driven; sub-checks 18a / 18b / 18c)
**Primitive:** [`core/deploy/tools/check-version-anchors.py`](../deploy/tools/check-version-anchors.py)
**Registry:** [`core/specs/framework-catalog.md`](../specs/framework-catalog.md)
**ADR:** the catalog-registry-vs-corpus-scan decision (catalog-registry vs prose corpus-scan — registry chosen, operator-ratified at Collective Review)

---

## 1. Purpose

Make the platform's framework corpus auditable and its review burden bounded. The platform references many named frameworks (PMBOK, SAFe, Nonaka SECI, Diátaxis, ADKAR, Cost of Delay, three-gulfs-methodology, failure-mode-standard, review-discipline-principles, …) but had no shared catalog, no version-anchor convention, and an implicit uniform review cadence. Frameworks evolve at different rates — SAFe ships major revisions every 1–2 years; Nonaka SECI has been stable since 1995. A uniform cadence wastes review effort on stable frameworks and misses updates on evolving ones (cf. a stale framework-version claim that survived in a governance file when the framework had long since moved on).

The protocol codifies (a) what the catalog registry is and what counts as a missing/inconsistent anchor, (b) the version-anchor convention, (c) the tiered review cadence and when reviews trigger, (d) what tooling enforces detection, (e) the escalation path, and (f) the flip-to-enforce timeline that prevents warn-mode from normalizing drift.

---

## 2. Catalog Registry & Anchor Categories

The **catalog** ([`framework-catalog.md`](../specs/framework-catalog.md)) is the governed registry — a YAML-frontmatter + 11-column markdown table, one row per framework. It is the **single source of truth** for version anchors and the registry the deploy.sh check reads (parallels Check 13's `TEMPLATE_SYNC_MAP`, **not** Check 14's corpus glob — see the catalog-registry-vs-corpus-scan decision).

Three drift patterns the protocol detects:

| Pattern | Description | Detection |
|---|---|---|
| **A — catalog incompleteness** | A catalog row is missing a required field (`framework`, `class`, `version_anchor`, `tier`, `last_reviewed`, `next_review_due`), has an out-of-enum `class`/`tier`, or `review_cadence` ≠ the cadence implied by `tier` | Check 18a (structural, ~zero-FP) |
| **B — catalog↔doc anchor divergence** | A framework's canonical doc carries YAML `framework_version_anchor:` frontmatter that disagrees with the catalog's authoritative `version_anchor` | Check 18b (consistency; SKIPs no-frontmatter docs) |
| **C — cadence aging** | A framework's `next_review_due` is on/before today — the framework is overdue for a tier/anchor review | Check 18c (informational aging signal) |

Pattern B is structurally bounded: docs without YAML frontmatter are **SKIPped, not failed** (documented v1 limitation, parallels the doc-link Pattern-C manual-checklist deferral in [`doc-link-maintenance-protocol.md`](doc-link-maintenance-protocol.md) § 6). Prose corpus-scan ("grep every doc for framework names lacking an adjacent version token") is semantic, NLP-hard, high-false-positive, and is **out of scope** per the catalog-registry-vs-corpus-scan decision — the catalog-completeness surface is the governed mechanism (new frameworks enter the platform *via the catalog* by convention).

---

## 3. Tiered Review Cadence

The tier-assignment rule is objective (not vibes) and is the authoritative copy codified in [OPERATIONS.md § Framework Review Cadence Protocol](../governance/OPERATIONS.md). Summarized:

| Tier | Assignment criterion | Cadence | `next_review_due` |
|---|---|---|---|
| **stable** | EXTERNAL: canonical source unchanged ≥5y AND no active revision program. INTERNAL: unchanged ≥2 minor releases | 36 months | `last_reviewed` + 36mo |
| **evolving** | EXTERNAL: major revisions on a 1–3y cadence. INTERNAL: edited within the last 2 minor releases | 12 months | `last_reviewed` + 12mo |
| **emerging** | Industry not yet settled, OR an INTERNAL standard in its first 2 minor releases of life | continuous | `continuous` (review every release touching the consuming surface) |

The review schedule is **catalog-driven, not a uniform calendar**: the operative query is "scan the catalog for rows where `next_review_due ≤ today`" (surfaced by Check 18c, parallels Check 17's aging signal). Tier is re-evaluated at every triggered review — a framework may graduate `emerging → evolving → stable` (or regress) as its canonical source's revision behavior changes.

---

## 4. Tooling

### 4.1 Primitive script

[`core/deploy/tools/check-version-anchors.py`](../deploy/tools/check-version-anchors.py) — Python stdlib-only (`/usr/bin/python3` 3.9+, matching the `block-rm-prefer-trash.sh` / `check-doc-links.py` posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md)).

**Interface contract:**
```
python3 core/deploy/tools/check-version-anchors.py \
  --catalog-path core/specs/framework-catalog.md \
  [--output-format tsv|json] \
  [--self-test]

Output (TSV, default):
  framework<TAB>check<TAB>detail<TAB>severity

check ∈ 18a-completeness | 18b-consistency | 18c-aging
severity ∈ P1 (structural/consistency) | P3 (aging informational)
Exit codes: 0 = no findings, 1 = findings found
```

**Self-test:** `python3 core/deploy/tools/check-version-anchors.py --self-test` runs an internal smoke test (catalog parse + 18a/18b/18c logic + clean-catalog zero-finding) and exits 0 on pass.

### 4.2 Enforcement-surface integration

| Check | Scope | Source |
|---|---|---|
| **Check 18** | Catalog registry ([`framework-catalog.md`](../specs/framework-catalog.md)) completeness + catalog↔doc anchor consistency + cadence aging | This protocol |

Check 18 invokes the primitive with the **Check 14 error-isolation idiom**: primitive-missing → `flag_warn_or_issue` (not crash); `/usr/bin/python3`-missing → flag (not crash); `output=$(… 2>&1) || exit=$?`. It is gated by the shared `$DEPLOY_CHECK_MODE` / `flag_warn_or_issue` mechanism (deploy.sh — same plumbing as Checks 8–10 / 14 / 15 / 16 / 17; no new mode infrastructure).

**Forecast-discipline classification:** Check 18 is **content-resolving** (inspects file content — catalog table + doc frontmatter — via the source tree; same class as Check 14). It is **NOT history-resolving** (no commit-metadata/trailer/message inspection). Warn-mode findings on this release's own `--check` resolve when Stage 6 lands the catalog rows + the demonstration-doc anchors — a content state achieved within this release's Engineering. No history-level deploy-resolution forecast is made.

---

## 5. Version-Anchor Convention

**The catalog `version_anchor` column is the single authoritative source. Per-doc frontmatter is a *derived demonstration*, not the source** (one concept, one home — [`duplicate-source-discipline.md`](duplicate-source-discipline.md) register-or-remove).

- **Authoritative:** the [`framework-catalog.md`](../specs/framework-catalog.md) `version_anchor` cell.
- **EXTERNAL anchors** cite the edition/year of the framework's canonical source (`PMBOK 7th (2021)`, `SAFe 6.0`, `Nonaka SECI (1995)`, `Scrum Guide 2020`). `(current)` / `(rolling)` is a permitted value for living-standard frameworks (Diátaxis) — the anchor records the *adoption edition*; `last_reviewed` carries the freshness signal.
- **INTERNAL anchors** cite the platform release tag at last material edit. This **composes with** [`version-field-semantics.md`](version-field-semantics.md) — same `vMAJOR.MINOR` grammar, parallel intent ("validated against this release's contracts").
- **Demonstration (where applicable):** docs that **already carry YAML frontmatter** add a `framework_version_anchor: "<value matching catalog>"` key. Demonstration targets (≥3 per the protocol AC): `review-discipline-principles.md` + `decision-discipline.md` (YAML frontmatter → Check 18b machine-checks them) + `methodology-parameterization-v1.md` (inline `**Status:**`-style metadata → the anchor is demonstrated via a native `**Framework version anchor:**` line; Check 18b SKIPs it per the no-frontmatter rule).
- **Where NOT applicable:** docs with no YAML frontmatter (`three-gulfs-methodology.md`, `failure-mode-standard.md`, `methodology-parameterization-v1.md`, `five-function-spine-and-process-flows.md`) keep their existing inline metadata convention. **No YAML frontmatter is force-added in this release** (high blast radius for zero correctness gain — the catalog is already authoritative; frontmatter backfill is a separate F-3-class corpus-hygiene concern, cf. [`doc-link-maintenance-protocol.md`](doc-link-maintenance-protocol.md) § 10).

A doc-frontmatter anchor that drifts from the catalog is a *liability*, not a benefit — Check 18b exists precisely to catch that divergence on the YAML-frontmatter subset.

---

## 6. Manual-Checklist Clause for Prose References

The catalog-registry check (Check 18) does not scan prose for framework names. A framework referenced in prose but absent from the catalog is not auto-detected (the accepted ADR consequence). Until/unless a future scope-expansion Issue introduces prose corpus-scan, operators executing any of the following workflows MUST perform a manual catalog-coverage scan:

1. **New framework introduction** (any release that adopts a named external methodology/standard, or promotes an INTERNAL standard): confirm a catalog row exists before merge. Add the row in the same release.
2. **Post-reorg / major content migration**: spot-check that migrated content's named frameworks are catalog-registered:
   ```bash
   grep -rEn "\b(PMBOK|SAFe|Scrum|Kanban|PRINCE2|SECI|Diátaxis|ADKAR|Cost of Delay)\b" \
     core/ core/governance/ core/rules/ \
     | grep -viE "framework-catalog\.md|framework-corpus-discipline\.md"
   ```
   Any named framework recurring in prose with no catalog row → add a catalog row (or, if intentionally inline-only, confirm it is acceptably out of registry scope).
3. **Stage 9 Plan Review** (release readiness): scan the release's touched files for framework references whose version anchor should now be updated (e.g., a doc still citing `SAFe 5.0` when the catalog anchor is `SAFe 6.0`).

Findings route to the standard surgical-fix path — small commits, parser-clean PR body, catalog row added/corrected.

---

## 7. Escalation Path

| Finding type | Routing |
|---|---|
| **18a completeness (P1) in the catalog** | Tier 1 commit on the current release branch (catalog is mechanically fixable), or surface to operator if a schema decision is implicated |
| **18b catalog↔doc divergence (P1)** | Bundle the anchor reconciliation into the current release as a surgical fix; create a GitHub issue if not already tracked |
| **18c cadence aging (P3, informational)** | Operator triage: re-review the framework (anchor still current? tier still right? bump `last_reviewed`/`next_review_due`), or accept-as-residual with rationale, or re-tier |
| **Net-new framework in prose, no catalog row** (manual-checklist finding) | Operator decides: add catalog row this release / defer to next / accept as intentionally inline-only |

Stage 7 Dev Testing and Stage 8 QA Testing inherit Check 18 via `./deploy.sh --check`; findings appear in the verification evidence.

---

## 8. Initial Enforcement Posture

**Mode:** warn-mode (per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) § Warn-Mode vs. Enforce-Mode shakedown precedent for Checks 8/9/10, and the [`doc-link-maintenance-protocol.md`](doc-link-maintenance-protocol.md) § 8 precedent for Checks 14/15).

**Mechanism:** Check 18 routes findings through the shared `flag_warn_or_issue` helper. In warn-mode it logs a `WARN` + appends to `.claude/hooks/deploy-check-warn-log.jsonl` and does **not** increment `ISSUES` (does not block deploy). Gated by `.claude/hooks/deploy-check.mode` (`warn` / `enforce` / `off`; absent file → `warn`).

**Rationale (R6 — verbatim class):** the catalog, the convention, the primitive, and Check 18 itself all ship *in this release*. Check 18 runs during this release's own `./deploy.sh --check` at Stage 12 Execute / Stage 13 Close (including the `--check` that this release's own deployment triggers). Always-enforce on day 1 would block the very release that introduces the check, the moment any seed row is still settling through Stage 8 QA. Warn-mode ships the check + surfaces drift without blocking, gives the operator visibility into any seed-catalog drift, and matches the established Check 8/9/10/14/15/16/17 rollout pattern.

---

## 9. Flip-to-Enforce Timeline (Governance-Theater Mitigation)

**MANDATORY clause** (warn-mode without operator-driven review degrades to ceremony; this section prevents that — same governance-theater mitigation as [`doc-link-maintenance-protocol.md`](doc-link-maintenance-protocol.md) § 9 / Collective Review CR-D6).

The protocol commits to a flip-to-enforce checkpoint at the following thresholds, whichever comes first:

| Threshold | Action |
|---|---|
| **2–3 releases post-merge** | Operator-driven review of `.claude/hooks/deploy-check-warn-log.jsonl` Check-18 entries |
| **Catalog 18a-clean + zero 18b mismatches for 2 consecutive releases** | Flip to enforce-mode via `.claude/hooks/deploy-check.mode` |
| **Each subsequent release until the flip** | Operator must explicitly defer the flip with rationale (codified at that release's Stage 13 Close); silent deferral is a process violation |

**Responsible party:** Workspace owner ([OPERATOR_NAME]). The **first Stage 13 Close after this protocol takes effect MUST include a "Check 18 flip-to-enforce assessment" line item.**

**Reversibility:** Flip-to-enforce is reversible — a single-line edit in `.claude/hooks/deploy-check.mode`. If enforce-mode produces a false-positive flood post-flip, revert to warn-mode while addressing the root cause.

### Explicit Reflexive Self-Exemption Cutover

The following cutover clause is **mandatory and verbatim** (the reflexive self-exemption pattern, same class as `release-process.md` QC4-05 / -D6):

> The enforce-mode cutover applies to all releases going forward.

---

## 10. Cross-References

- **Stage 5 spec:** sub-task (D-decisions ratified at Collective Review)
- **ADR:** the catalog-registry-vs-corpus-scan decision (catalog-registry vs prose corpus-scan)
- **Registry:** [`framework-catalog.md`](../specs/framework-catalog.md)
- **Primitive:** [`check-version-anchors.py`](../deploy/tools/check-version-anchors.py)
- **Authoritative tier rule + review cadence:** [OPERATIONS.md § Framework Review Cadence Protocol](../governance/OPERATIONS.md)
- **Parallel anchor mechanism:** [`version-field-semantics.md`](version-field-semantics.md) (SKILL.md `version:` field — same release-tag grammar)
- **Warn-mode + flip-to-enforce precedent:** [`doc-link-maintenance-protocol.md`](doc-link-maintenance-protocol.md) § 8 / § 9
- **Shakedown precedent (hook layer):** [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) (warn / enforce / off pattern)

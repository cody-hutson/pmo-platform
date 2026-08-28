---
title: Practice-Efficacy Framework — Signal Catalog · Cadence · Trigger Protocol
purpose: The measurement framework for evaluating whether the platform's adopted practices produce their intended outcomes — a signal catalog, cadence, and trigger protocol distinct from staleness and drift.
type: standard
framework_version_anchor: "v11.13"
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: OPERATIONS.md (efficacy review cadence); km-governance-framework.md; framework-catalog.md (the practice-efficacy-framework INTERNAL row); operators reviewing whether adopted practices produce outcomes
---
<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->
# Practice-Efficacy Framework — Signal Catalog · Cadence · Trigger Protocol

**Origin:** the KM Governance and Efficacy release. Establishes a measurement framework for evaluating whether the platform's adopted practices are actually producing the intended outcomes — distinct from staleness and drift.
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md).
**Class:** INTERNAL framework (per [`framework-catalog.md`](../specs/framework-catalog.md)); prescriptive — mandate language predominates.
**Version anchor:** per [`version-field-semantics.md`](version-field-semantics.md) release-tag-at-last-material-edit.
**Primary consumer:** Workspace owner / release-orchestration spokes that surface practice review-due lists at Stage 13 Close.
**Hard downstream consumer:** the downstream KM Governance work (retirement triggers source from this framework's efficacy signals). Schema-stability commitment in §10 is the contract.
**Soft downstream consumers:** `pmo-qa-auditor` KM scanning (may consume SIG-G3 as complementary signal); records-management (may consume efficacy signals as disposition-decision input); periodic `<OPERATOR_INSTANCE_ANALYSIS_PATH>/` efficacy reports (future).
**Status:** Canonical.
**Introduced:** km-governance-and-efficacy release.

---

## §1 Purpose and Scope

The practice-efficacy framework codifies HOW the platform measures whether an adopted practice — a governance rule, a skill, a protocol, a framework, a convention — is **producing the outcome it was adopted to produce**. It is the third leg of a three-concern KM governance stool: **staleness** (is the content current?), **drift** (are cross-references intact and platform consistent?), and **efficacy** (is the practice actually working?).

The framework does NOT govern WHICH practices to retire — that decision class belongs to KM retirement-trigger governance and consumes this framework's signals as inputs. The framework provides:

1. A **6-signal catalog** with definitions, measurement mechanisms, threshold bands, and forward-compatibility flags (§3).
2. A **cadence-derivation rule** binding efficacy-review frequency to framework-catalog tier (§5).
3. A **3-trigger re-evaluation protocol** with thresholds, windows, and bound actions (§6).
4. An **operational ledger schema** for recording efficacy measurements over time (§7).
5. **Scope boundaries** distinguishing this framework from staleness and drift concerns (§9).
6. A **schema-stability commitment** to downstream consumers (§10).

**Out of scope (explicit):**

- Closing, merging, relabeling, or de-milestoning adjacent KM-governance issues (per the least-destructive-disposition discipline; boundaries are documented in §9 only).
- Pipeline-event-log schema extension for `event_type: practice-efficacy` (deferred to a later release at first-event-fires-time per §11).
- Skill SKILL.md modifications. No skill behavior changes at this framework's ship.
- Automated `check-practice-efficacy.sh` tooling. The framework specifies the requirement; tool implementation is a future release.
- Layer 2 (`projects/`) files. The framework governs Layer 1 only.

**Reading order.** A consumer applying the framework reads §3 (signal catalog) → §5 (cadence) → §6 (trigger protocol) → §7 (ledger schema) → §9 (boundaries) in that order. Sections §1, §2, §4, §8, §10, §11 are reference / discipline / cutover content read once.

---

## §2 Signal-Catalog Overview

The 6-signal catalog (§3) is the framework's central concept-model artifact. The catalog organizes signals along **two orthogonal dimensions**:

**Dimension 1 — Signal class** (when the signal fires relative to the outcome it predicts):

| Class | Meaning | Cardinality in catalog | What it answers |
|---|---|---|---|
| **leading** | Surfaces BEFORE the outcome it predicts; usage-driven | 2 (SIG-L1, SIG-L2) | "Are people adopting the practice in the way it was designed?" |
| **lagging** | Surfaces AFTER the outcome it predicts; consequence-driven | 4 (SIG-G1, SIG-G2, SIG-G3, SIG-G4) | "Did the practice produce the outcome we expected?" |

**Dimension 2 — Measurement readiness** (whether the signal is operational today vs. forward-compatible-with-flag):

| Flag value | Meaning | Implication |
|---|---|---|
| `YES` | Measurement mechanism exists and is operational at ship | Signal fires triggers per §6 |
| `PARTIAL` | Measurement is manual today; auto-instrumentation pending downstream issue | Signal contributes to manual review; auto-trigger fires after instrumentation lands |
| `NO` | Measurement mechanism does not exist yet | Signal codified for forward-compatibility; does NOT fire triggers until measurement instrumentation ships |

**Concept-model rendering** (per [`design-artifact-standard.md` § 6](design-artifact-standard.md) concept-model standard — Tier-A activated artifact #1):

```
                     ┌─ Signal class ──────────────────────────┐
                     │  leading            │  lagging          │
┌─ Measurable? ──────┼─────────────────────┼───────────────────┤
│  YES (operational) │  SIG-L1             │  SIG-G1, SIG-G2,  │
│                    │                     │  SIG-G3           │
│  PARTIAL (manual)  │  SIG-L2             │  SIG-G4           │
│  NO (deferred)     │  (none this release) │  (none this release) │
└────────────────────┴─────────────────────┴───────────────────┘
```

**Asymmetry note.** 2 leading + 4 lagging is intentional. Lagging signals are easier to measure (the outcome has already manifested in the evidence trail) and form the contract that the downstream KM Governance work consumes for retirement triggers (`retirement_trigger_eligible: yes` is set on all 4 lagging signals; both leading signals are `no` — see §3 and §10 schema-stability commitment).

---

## §3 Signal Catalog

The catalog defines 6 signals — 2 leading + 4 lagging. Each signal has a stable ID that **never changes** (per §10 schema-stability commitment). Adding new signals is permitted (additive); reassigning, renaming, or removing existing IDs is forbidden.

| Signal ID | Name | Class | Measurable Today? | Retirement-trigger-eligible? |
|---|---|---|---|---|
| `SIG-L1` | Adoption frequency | leading | YES | NO |
| `SIG-L2` | Deviation rate from recommended approach | leading | PARTIAL | NO |
| `SIG-G1` | Outcome quality | lagging | YES | **YES** |
| `SIG-G2` | Rework rate | lagging | YES | **YES** |
| `SIG-G3` | Operator-correction frequency | lagging | YES | **YES** |
| `SIG-G4` | Release failure rate attributable to practice | lagging | PARTIAL | **YES** |

Detail per signal follows. Each signal is one third-level subsection so the verification grep `^### SIG-` returns 6 hits.

### SIG-L1 — Adoption frequency

**Class:** leading.
**Definition:** Number of distinct release-stage spokes, commits, or hub Decision Briefings citing the practice per release.
**Measurement mechanism:** `git log --grep "<practice-id>" --since="<release-base>" --until="<release-tip>" | wc -l` combined with `grep -rn "<practice-id>" release/releases/plans/v<X.Y>_RELEASE_PLAN.md` to count plan-level citations.
**Cadence:** per-release.
**Threshold bands:**

| Band | Threshold | Interpretation |
|---|---|---|
| good | ≥3 invocations / release | Practice is in active use as designed |
| concerning | 1–2 invocations / release | Practice usage is sparse; may be context-specific or under-adopted |
| critical | 0 invocations / release across 3 consecutive releases | Practice is effectively dormant — investigate cause (deprecated? superseded? inapplicable?) |

**Measurable Today?** YES.
**Retirement-trigger-eligible?** NO. Low adoption may reflect inapplicability rather than low efficacy — a practice may be load-bearing in rare contexts and produce its intended outcome whenever it does fire.

### SIG-L2 — Deviation rate from recommended approach

**Class:** leading.
**Definition:** Fraction of decisions where the hub's M3 Pattern Cache Scan (per [`decision-discipline.md § 2.3`](../disciplines/decision-discipline.md)) cited the practice but the operator overrode it.
**Measurement mechanism:** Today, manual review of hub-session transcripts: `grep -A 5 "Pattern Cache Scan" <transcript> | grep -c "operator override"`. Will be auto-instrumented when pipeline-event-log audit-trail lands (operator-override events recorded as `event_subtype: m3-override` in `pipeline-event-log.md`).
**Cadence:** per-release.
**Threshold bands:**

| Band | Threshold | Interpretation |
|---|---|---|
| good | <10% override rate | Practice's recommendations match operator judgment in most cases |
| concerning | 10–30% override rate | Practice may need localization tuning or scope refinement |
| critical | ≥30% override rate | Practice's recommendation logic is misaligned — re-evaluate definition |

**Measurable Today?** PARTIAL (manual today; auto-instrumented when pipeline-event-log audit-trail lands).
**Retirement-trigger-eligible?** NO. High deviation may reflect a localization need rather than low efficacy — see §10 schema-stability commitment for rationale.

### SIG-G1 — Outcome quality

**Class:** lagging.
**Definition:** Density of Tier 1 / 2 / 3 [ADJUST] findings raised by Stage 7 Dev Testing per release, scoped to files owned by the practice (as declared in framework-catalog `canonical_doc` or skill `references/` path).
**Measurement mechanism:** `gh issue list --label "sub-task" --search "DT" --json comments` filtered by release window; count of Tier 1+2+3 findings naming files in the practice's affected-file scope, normalized per release count.
**Cadence:** per-release.
**Threshold bands:**

| Band | Threshold | Interpretation |
|---|---|---|
| good | <2 DT findings / release for files in practice scope | Outcome quality holds at Stage 7 review |
| concerning | 2–5 DT findings / release | Outcome quality is degrading; investigate root cause |
| critical | ≥5 DT findings / release OR ≥1 Tier 3 PLAN REJECTION | Practice's outcome is failing at review — re-evaluate definition |

**Measurable Today?** YES.
**Retirement-trigger-eligible?** YES — per §10 schema-stability commitment (1 of 4 lagging signals consumed by the downstream retirement-trigger protocol).

### SIG-G2 — Rework rate

**Class:** lagging.
**Definition:** Number of distinct `fix(*)` or `chore(*)` commits per 5-release rolling window whose diff touches a Layer 1 file owned by the practice.
**Measurement mechanism:** `git log --grep "^fix\|^chore" --since="<5-release-window-base>" -- <practice-owned-files> | awk '/^commit /{c++} END{print c}'` (count distinct commits).
**Cadence:** 5-release rolling window.
**Threshold bands:**

| Band | Threshold | Interpretation |
|---|---|---|
| good | 0–1 fix commits / 5 releases | Practice is stable post-adoption |
| concerning | 2–3 fix commits / 5 releases | Practice has accumulating remediation cost |
| critical | ≥4 fix commits / 5 releases | Practice requires repeated rescue; scope refinement or retirement candidate |

**Measurable Today?** YES.
**Retirement-trigger-eligible?** YES.

### SIG-G3 — Operator-correction frequency

**Class:** lagging.
**Definition:** Number of observation-log entries OR promoted confirmed-pattern entries whose `(domain, theme)` pair overlaps the practice's scope, measured over a 180-day rolling window.
**Measurement mechanism:** count observation-log entries tagged with the practice's theme (filtered by date ≥ now-180d) + count promoted confirmed-pattern entries for the same theme in the same window.
**Cadence:** 180-day rolling window.
**Threshold bands:**

| Band | Threshold | Interpretation |
|---|---|---|
| good | 0 observations / 180d | Operator is not correcting the practice — it's working as intended |
| concerning | 1–2 observations / 180d | Operator has noted issues but pattern has not crystallized |
| critical | ≥3 observations / 180d | Pattern has crystallized via emergence rule ([`decision-discipline.md § 4.2`](../disciplines/decision-discipline.md)) — practice needs revision (matches T-OP trigger threshold) |

**Measurable Today?** YES (the observation log is live per [`decision-discipline.md § 4.1`](../disciplines/decision-discipline.md)).
**Retirement-trigger-eligible?** YES.

### SIG-G4 — Release failure rate attributable to practice

**Class:** lagging.
**Definition:** Number of pipeline-event-log entries with `event_subtype: practice-failure` AND payload citing the practice ID, measured over a 5-release rolling window.
**Measurement mechanism:** `query-pipeline-event.sh --event-subtype practice-failure --window 5 | grep "practice:<practice-id>"`. The release join key is the milestone slug per `pipeline-event-log-schema.md` § 2a; scope a single release with `--release <milestone-slug>` rather than matching the raw column, which is polymorphic and not uniquely resolvable.
**Cadence:** 5-release rolling window.
**Threshold bands:**

| Band | Threshold | Interpretation |
|---|---|---|
| good | 0 incidents / 5 releases | Practice has not contributed to release failures |
| concerning | 1 incident / 5 releases | Investigate incident — practice may need scope refinement |
| critical | ≥2 incidents / 5 releases OR ≥1 critical-severity incident | Practice is contributing to release failures — hot-patch + retirement-candidate review |

**Measurable Today?** PARTIAL — the `event_subtype: practice-failure` registration in [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) is deferred to first-event-fires-time per §11. Until the schema extension lands, T-CI manual annotation in the pipeline-event-log payload field is the workaround.
**Retirement-trigger-eligible?** YES.

---

## §4 Measurement Mechanisms

This section unpacks the measurement primitives the §3 signals depend on. Each primitive is a deterministic command or file read — agents and operators can re-execute and reproduce results.

**Primitive 1 — Git log scope query.** Used by SIG-L1, SIG-G2.

```bash
git log --grep "<pattern>" --since="<iso-date-or-tag>" --until="<iso-date-or-tag>" -- <path1> [<path2>...]
```

The `--grep` argument matches commit messages; the `--` separator scopes to specific file paths. Combined with `wc -l` (commit count) or `awk` (distinct-commit count) at the consumer.

**Primitive 2 — GitHub Issues + comments query.** Used by SIG-G1.

```bash
gh issue list --label "sub-task" --search "DT" --milestone "v<X.Y>" --json number,title,comments \
  --jq '.[] | select(.comments | length > 0) | {number, title, comments: .comments | map(select(.body | test("Tier [1-3] \\[ADJUST\\]"))) | length}'
```

Counts DT findings classified as Tier 1 / 2 / 3 [ADJUST] per release-window milestone.

**Primitive 3 — Observation log + confirmed-pattern query.** Used by SIG-G3.

```text
# Observation count in 180d window for a theme:
#   count observation-log entries tagged `theme: <practice-theme>` (filter to date ≥ now-180d)

# Promoted confirmed-pattern count for the same theme:
#   count promoted confirmed-pattern entries for <practice-theme> in the same window
```

(Both queries run against the user auto-memory store — the observation log and the promoted confirmed-pattern entries — which is operator-local and out of this repo.)

The 180-day staleness window matches the emergence-rule staleness window at [`decision-discipline.md § 4.2`](../disciplines/decision-discipline.md), so SIG-G3 is the natural efficacy mirror of the operator-correction promotion pipeline.

**Primitive 4 — Pipeline-event-log query.** Used by SIG-G4 (when schema extension lands) and SIG-L2 (when audit-trail lands).

```bash
grep "event_subtype:<subtype>" <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md \
  | awk -F'|' '{print $2}' | sort -u
```

The pipeline-event-log is append-only; consumers can scope by `version:` column or `ts_iso` field to narrow the rolling window.

**Primitive readiness matrix:**

| Primitive | Status | Affects |
|---|---|---|
| Git log scope query | OPERATIONAL | SIG-L1, SIG-G2 |
| GitHub Issues + comments query | OPERATIONAL | SIG-G1 |
| Observation log + confirmed-pattern query | OPERATIONAL | SIG-G3 |
| Pipeline-event-log query | PARTIAL (schema needs `event_subtype: practice-failure` registration; deferred to first-event-fires-time per §11) | SIG-G4, SIG-L2 |

---

## §5 Cadence Binding

Efficacy-review cadence is **derived from the practice's framework-catalog `tier` column** rather than carried as a parallel column. This keeps the framework-catalog schema unchanged (per [`CLAUDE.md § Universal Preferences`](<OPERATOR_INSTANCE_CLAUDE_MD>) "Parameterize over hardcode" + [`duplicate-source-discipline.md`](duplicate-source-discipline.md) register-or-remove rule).

**Derivation rule:**

| framework-catalog `tier` | Meta-review cadence (framework-catalog `review_cadence`) | **Efficacy-review cadence (this framework derivation)** | Rationale |
|---|---|---|---|
| `stable` | 36mo | **12mo (annual)** | Mature practices have lower drift risk; annual sanity-check on outcome quality |
| `evolving` | 12mo | **6mo (biannual)** | Practices in flux need tighter feedback to catch divergence early |
| `emerging` | continuous (event-triggered) | **3mo (quarterly)** | New practices have highest uncertainty; quarterly checkpoint surfaces calibration needs |

**Event-triggered overlay (orthogonal — applies to all tiers).** Any §6 trigger firing (T-OP / T-RW / T-CI) initiates an IMMEDIATE efficacy review on top of the tier-floor cadence. The cadence is the floor; trigger fire is the ceiling.

**Default for unregistered practices.** Practices not yet registered in [`framework-catalog.md`](../specs/framework-catalog.md) default to `tier: emerging` for efficacy purposes (quarterly review + event-triggered overlay) until they are catalog-registered.

**Vocabulary discipline.** The catalog enum `stable / evolving / emerging` is the canonical vocabulary. The body-level language `mature / new / crisis-response` from the originating proposal maps as: `mature → stable`, `new → emerging`, `crisis-response → event-triggered overlay (applies orthogonally to any tier)`. See §10 schema-stability commitment for the binding contract; see also the F1 [ADJUST] body update applied at Stage 6 commit-time.

---

## §6 Trigger Protocol

Three named triggers — **T-OP**, **T-RW**, **T-CI** — fire IMMEDIATE efficacy review independent of the §5 cadence floor. Each trigger has a stable ID that **never changes** (per §10 schema-stability commitment). Adding new triggers (e.g., T-LD for adoption-decay) is permitted; reassigning, renaming, or removing existing IDs is forbidden.

The trigger fire SURFACES the condition to the operator. Trigger fire does NOT auto-execute action — the operator renders the disposition (revise / refine / retire / accept-as-residual). The framework's job is to surface; the operator's job is to dispose.

Detail per trigger follows. Each trigger is one third-level subsection so the verification grep `^### T-` returns 3 hits.

### T-OP — Operator-correction frequency

**Threshold:** ≥3 observation-log entries OR ≥1 promoted confirmed-pattern entry whose `(domain, theme)` overlaps practice scope.
**Measurement window:** 90-day rolling.
**Mechanism (verifiable):**

```text
# count observation-log entries tagged `theme: <practice-theme>` (filter by date ≥ now-90d before counting)
# count promoted confirmed-pattern entries for <practice-theme>
# (both run against the user auto-memory store, which is operator-local and out of this repo)
```

**Semantics:** "Operator has corrected this practice ≥3 times in 90 days OR escalated emergence-rule promotion."
**Bound action when fired:** Re-evaluation review (operator session); revise rubric / clarify scope / consider scope-refinement.
**Severity:** MEDIUM (calibration signal — process drift).
**Confidence on threshold:** `[CALIBRATE-AFTER-3]` MEDIUM-confidence per [`decision-discipline.md § 5`](../disciplines/decision-discipline.md) calibration discipline.

### T-RW — Rework rate

**Threshold:** ≥2 distinct `fix(*)` / `chore(*)` commits whose diff touches a Layer 1 file owned by the practice.
**Measurement window:** 5-release rolling.
**Mechanism (verifiable):**

```bash
git log --grep "^fix\|^chore" --since="<5-release-base-tag>" -- <practice-owned-files> \
  | awk '/^commit /{c++} END{print c}'
```

**Semantics:** "Practice requires ≥2 corrective re-implementations across 5 releases."
**Bound action when fired:** Re-evaluation review (operator session); consider scope refinement OR mark practice for retirement-candidate review.
**Severity:** MEDIUM (process-drift signal).
**Confidence on threshold:** `[CALIBRATE-AFTER-3]` MEDIUM-confidence.

### T-CI — Critical incident attributed to practice

**Threshold:** ≥1 pipeline-event-log entry with `event_type: incident` AND `event_subtype: practice-failure` AND payload containing `<practice-id>`.
**Measurement window:** Since last efficacy review (resets when human review completes; no calendar window applies).
**Mechanism (verifiable):**

```bash
grep "event_subtype:practice-failure" <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md \
  | grep "<practice-id>" \
  | awk -F'|' '$1 >= "<last-review-iso-date>"'
```

**Semantics:** "Practice contributed to ≥1 release-impacting incident since last efficacy review."
**Bound action when fired:** IMMEDIATE re-evaluation (within 5 business days); consider hot-patch + deprecation-candidate review.
**Severity:** HIGH (incident signal — release-impacting).
**Confidence on threshold:** HIGH (incident is binary — one is one too many). No calibration applies.

### Trigger composition rules

- **Multiple triggers may fire simultaneously.** When ≥2 triggers fire on the same practice in the same measurement cycle, escalate severity one tier (MEDIUM → HIGH; HIGH stays HIGH).
- **Trigger fire does NOT auto-execute action.** The framework's `surfacing` posture: log the trigger, attach it to the practice's Stage 13 release-readiness checklist, surface to operator. Operator renders disposition.
- **Calibration discipline.** Stage 13 Close at the 3rd post-cutover release applying the framework auto-spawns a calibration GitHub Issue reviewing T-OP / T-RW / T-CI threshold validity per the workspace `[CALIBRATE-AFTER-3]` precedent (matches [`release-process.md § Stage 3 Bundle A7`](../../release/governance/release-process.md) precedent for bundle-refresh calibration).

### Trigger × Cadence 2D model (concept-model — Tier-A activated artifact #2)

The §5 cadence-binding and §6 trigger-protocol compose into a 2D measurement protocol. The cadence is the floor; the trigger is the IMMEDIATE overlay. The relationship visualizes as:

```
                ┌───────────────────────────────────────────────────┐
                │                                                   │
                │       ┌─ Cadence floor (§5 derivation) ─┐         │
                │       │                                 │         │
   practice  ───┼───────► tier: stable    → 12mo review  ─┼───►     │
   in catalog   │       │ tier: evolving  →  6mo review   │   efficacy
                │       │ tier: emerging  →  3mo review   │   review
                │       └─────────────────────────────────┘    fires │
                │                  ▲                                │
                │                  │  IMMEDIATE overlay (§6)        │
                │                  │                                │
                │       ┌─────────────────────────────────┐         │
                │       │  T-OP fires (operator-correction) ────►   │
                │       │  T-RW fires (rework)              ────►   │
                │       │  T-CI fires (incident)            ────►   │
                │       └─────────────────────────────────┘         │
                │                                                   │
                └───────────────────────────────────────────────────┘
```

**Two outcome paths:**

1. **Cadence-floor fire** — review fires at the tier-derived calendar date with no triggers. Outcome: routine sanity-check; ledger row appended with `trigger_fired: no`.
2. **Trigger overlay fire** — review fires IMMEDIATELY on trigger condition met, regardless of cadence position. Outcome: targeted re-evaluation; ledger row appended with `trigger_fired: yes` and `source_artifact:` pointing to the triggering evidence.

---

## §7 Ledger Schema

The **practice-efficacy-ledger** at [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/practice-efficacy-ledger.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/practice-efficacy-ledger.md) is the durable operational record of efficacy measurements. Each row records ONE measurement of ONE signal for ONE practice over ONE observation window. The ledger is append-only; rows are never edited or deleted post-write (matches the pipeline-event-log discipline at [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md)).

### Schema (10 columns)

| Column | Type | Populated when | Description |
|---|---|---|---|
| `practice_id` | string | row creation | Canonical practice identifier (`framework-catalog` row's `framework` column value OR `<skill-name>` for skill-implemented practices) |
| `signal_id` | enum `SIG-L1` / `SIG-L2` / `SIG-G1` / `SIG-G2` / `SIG-G3` / `SIG-G4` | row creation | Catalog signal being measured (per §3) |
| `signal_class` | enum `leading` / `lagging` | row creation | Per-signal classification (denormalized from §3 for reader convenience and forward-additive support) |
| `observation_window_start` | ISO date `YYYY-MM-DD` | row creation | Start of measurement window |
| `observation_window_end` | ISO date `YYYY-MM-DD` | row creation | End of measurement window |
| `measured_value` | numeric or `N/A` | row creation | Observed value (e.g., `3` corrections, `0.15` deviation rate) — exact unit per §3 signal definition |
| `threshold_band` | enum `good` / `concerning` / `critical` | row creation | Band per §3 signal catalog thresholds |
| `trigger_fired` | enum `yes` / `no` | row creation | Whether T-OP / T-RW / T-CI triggered as a result of this row's measurement |
| `source_artifact` | string | row creation | Pointer to evidence (e.g., observation-log entry, pipeline-event-log row, `git log SHA range`, `gh issue #N comment id`) |
| `review_due_at` | ISO date `YYYY-MM-DD` or `event-triggered` | row creation | Computed = `observation_window_end` + cadence per tier; populated as `event-triggered` when trigger fired |

### Schema invariants

- All 10 columns are required per row. `N/A` is a permitted value for `measured_value` when the signal's `Measurable Today?` flag is NO or PARTIAL and a placeholder row is being recorded for audit-trail integrity.
- `signal_id` and `signal_class` MUST match the §3 catalog mapping. The denormalization is forward-compatible (additive enum); inconsistent rows fail the framework's structural lint.
- `threshold_band` MUST be derived from `measured_value` against §3 thresholds — no operator override at the band level (override is captured at the disposition level via Stage 13 release-readiness checklist, NOT by mutating the band).
- Rows are written by efficacy-review sessions; readers include  (retirement-trigger sourcing), framework's own §11 review-due lookup, and periodic `<OPERATOR_INSTANCE_ANALYSIS_PATH>/` efficacy reports (future).

### Data-flow producer/consumer model (data-flow — Tier-A activated artifact #3)

The ledger participates in a multi-producer / multi-consumer data flow. The schema-stability commitment at §10 is the contract that makes the multi-consumer surface durable.

```
                     ┌──────────────────────────────────────────────┐
                     │              practice-efficacy-ledger.md     │
                     │              (append-only, 10-col schema)    │
                     └──────────────────────────────────────────────┘
                            ▲                            │
              [PRODUCERS]   │                            │  [CONSUMERS]
                            │                            ▼
  ┌─ Efficacy-review session (operator + framework spoke) ─┐    ┌─ §11 framework review-due lookup ─┐
  │  - Reads §3 signal catalog                             │    │  - Reads rows for cadence/trigger  │
  │  - Computes signal values from §4 primitives           │    │    state per practice              │
  │  - Appends row(s) per measurement                      │    └────────────────────────────────────┘
  └────────────────────────────────────────────────────────┘
                            │                            │
                            │                            ▼
  ┌─ Stage 13 Close spoke (release-readiness checklist) ──┐    ┌─  KM Governance retirement-trigger ┐
  │  - Reads "review-due since last release" rows         │    │  - Reads retirement_trigger_eligible   │
  │  - Surfaces practices with fired triggers             │    │    signal rows                         │
  │  - Appends new measurement rows post-disposition      │    │  - Composes triggers per its protocol  │
  └───────────────────────────────────────────────────────┘    └────────────────────────────────────────┘
                            │                            │
                            │                            ▼
  ┌─ Future automated check-practice-efficacy.sh ─────────┐    ┌─ Periodic analysis/ efficacy reports ──┐
  │  - Reads §3 + §5 + §6                                 │    │  - Reads ledger as data source         │
  │  - Computes per-practice signal values per release    │    │  - Generates aggregated reports        │
  │  - Appends batch rows                                 │    │    (future; not this release)          │
  └───────────────────────────────────────────────────────┘    └────────────────────────────────────────┘
```

**Coordination contract:** Schema-stability at §10 ensures consumers can rely on the 10-col schema across releases. Schema evolution is additive-only; consumers tolerate new columns trailing the existing 10.

---

## §8 Cross-References

This section enumerates the platform artifacts that this framework cross-references — both inward (artifacts this framework reads) and outward (artifacts that read this framework).

**Inward (read by this framework):**

| Artifact | Purpose |
|---|---|
| [`framework-catalog.md`](../specs/framework-catalog.md) | Source of the `tier` column that drives §5 cadence derivation; this framework registers itself as a row in the catalog |
| The observation log (user auto-memory store) | Source of SIG-G3 measurement data; observation count drives T-OP trigger |
| Promoted confirmed-pattern entries (user auto-memory store) | Promotion counts contribute to T-OP trigger |
| [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) | Source of SIG-G4 + T-CI trigger evidence (post first-event-fires registration) |
| [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) | Schema authority for the `event_subtype: practice-failure` extension deferred to a later release |
| [`decision-discipline.md`](../disciplines/decision-discipline.md) | Owns Pattern Cache Infrastructure (§4 of that doc); SIG-G3 is the efficacy mirror of operator-correction promotion |
| [`design-artifact-standard.md`](design-artifact-standard.md) | Tier-A activation criteria for the 3 design artifacts embedded in this framework (§3, §6, §7) |
| [`evidence-grounding-standard.md`](evidence-grounding-standard.md) | R3 ↔ R1 composition for cross-D consistency checks at Stage 5 |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | K1 placement model for this framework's standards/ location |

**Outward (artifacts that consume this framework's schema/contract):**

| Consumer | What is consumed | Schema-stability dependency |
|---|---|---|
| the downstream KM Governance work (retirement triggers) | Signal IDs + ledger row schema + `retirement_trigger_eligible` flag + trigger semantics | HARD (the downstream Stage 5 escalates Tier 2 [SCOPE CHANGE] back to this framework if schema gap surfaces) |
| `pmo-qa-auditor` KM scanning | SIG-G3 (operator-correction frequency) as complementary signal alongside staleness | SOFT (forward-state; integration is downstream work) |
| records-management | Efficacy signals as disposition-decision input for retention | SOFT (forward-state) |
| Periodic `<OPERATOR_INSTANCE_ANALYSIS_PATH>/` efficacy reports (future) | Ledger rows as data source for aggregated reporting | SOFT (no current consumer; reserved) |

**Forward-state integration with `pmo-qa-auditor`:** When `pmo-qa-auditor` gains KM scanning, the scanning mode MAY consume this framework's SIG-G3 as a complementary signal. The integration is downstream work tracked by a future Stage 5 plan. This release ships the framework only; no `pmo-qa-auditor` SKILL.md edits at ship.

---

## §9 Scope Boundary vs Staleness and Drift

This framework is **scoped distinctly** from staleness and drift. All three concerns operate at different layers of the same artifact, and consolidation would conflate orthogonal questions.

### Boundary table

| Concern | Question answered | Owning artifact / skill | Mechanism | Cross-reference TO this framework |
|---|---|---|---|---|
| **Staleness** | "Is this content current?" (out-of-date detection by age + criticality threshold per `km-protocols.md`) | `pmo-qa-auditor` skill via KM scanning capability | Documentation-debt audit + lifecycle-state check + freshness scan via `km-protocols.md` thresholds | When `pmo-qa-auditor` ships, OPTIONAL "see also" pointer to practice-efficacy-framework.md §3 SIG-G3 (operator-correction signal complements freshness scan) |
| **Drift** | "Are cross-references intact and platform consistent?" (cross-domain reference integrity + governance contradiction detection) | `health-check.sh` + [`.claude/rules/doc-link-maintenance.md`](../rules/doc-link-maintenance.md) Check 14 / Check 15 | Cross-domain link resolution + stale-reference scan + version/count-claim validation | NO reciprocal edit (closed issue) |
| **Efficacy** | "Is this practice actually producing the intended outcome?" (signal-driven measurement of WHETHER adopted practices are working) | THIS framework ([`practice-efficacy-framework.md`](practice-efficacy-framework.md)) | 6-signal catalog (§3) + tier-aligned cadence (§5) + 3-trigger protocol (§6) | OWN PATH — this is the framework |

### Boundary statement

**Scope boundary.** Practice efficacy (this framework) is distinct from staleness (content age + criticality) and drift (Check 14–15 cross-reference integrity). All three concerns operate at different layers of the same artifact: a practice may be FRESH (passes staleness scan) AND INTACT (passes drift scan) BUT INEFFECTIVE (fails this framework's efficacy signals — outcome quality declining, rework rate rising, operator-correction frequency climbing). Conversely, a practice may be STALE or DRIFTED yet still EFFICACIOUS if its core outcome continues to ship. Each concern requires its own measurement mechanism; consolidation would conflate orthogonal questions. The three frameworks compose by reference, not by absorption.

**Integration with `pmo-qa-auditor` KM scan (forward-state).** When `pmo-qa-auditor` gains KM scanning, the scanning mode MAY consume this framework's SIG-G3 (operator-correction frequency) as a complementary signal — high operator-correction frequency on a freshness-passing artifact suggests efficacy concern even when staleness scan reports no debt. The integration is downstream work tracked by a future Stage 5 plan; this release ships the framework only.

### Out-of-scope items (per the least-destructive-disposition discipline)

- **`pmo-qa-auditor` KM scanning (OPEN)** — NO closure, NO merge, NO relabel, NO de-milestone, NO reciprocal SKILL.md edits at this framework's ship. Boundary documentation lives in this §9 table ONLY.
- **Drift-scope closed issue** — NO modification. Closed-issue reference is informational; closed-issue body remains untouched.
- **Related closed issue** — NO modification. Referenced as "Relates to" in the originating issue body but no overlap requires action.

---

## §10 Cutover and Schema-Stability Commitment

### Cutover

This framework applies to platform-adopted practices from **the release after its publication onward**. **The framework's own publishing release is exempt** from its own efficacy-review forcing function (reflexive-pipeline-loop discipline — matches prior cutover precedents per [`release-process.md`](../../release/governance/release-process.md)). At ship, the framework is published; downstream consumers (Stage 13 release-readiness checklist line per the originating proposal) integrate it starting the release after publication.

The framework's framework-catalog entry self-registers with `tier: emerging` per §5 default-for-new-frameworks rule, with `review_cadence: continuous` per the catalog's `emerging`-tier derivation. The catalog row is the registration of record.

### Schema-stability commitment to the downstream KM Governance work

Downstream consumer the downstream KM Governance work (retirement triggers) hard-depends on this framework's schema. The following commitments are **STABLE** from this framework's ship onward; consumers may rely on them across releases:

1. **Signal IDs are STABLE** — `SIG-L1` (Adoption frequency), `SIG-L2` (Deviation rate from recommended approach), `SIG-G1` (Outcome quality), `SIG-G2` (Rework rate), `SIG-G3` (Operator-correction frequency), `SIG-G4` (Release failure rate attributable to practice). IDs will NOT be reassigned, renamed, or removed. ID-based foreign-key references from the the downstream KM Governance work schema will resolve.

2. **Ledger row schema (10 columns) is STABLE** — column names, types, populate-when semantics will NOT change. Consumers can write row-reading code with confidence the 10 columns will be there. Additive evolution (new columns trailing the 10) is permitted; existing columns are immutable.

3. **Signal-class enum (`leading` / `lagging`) is STABLE** — the 2-class taxonomy will NOT change. Consumers MAY filter by `signal_class`.

4. **`retirement_trigger_eligible` flag column is STABLE** — values are `yes` for the 4 lagging signals (`SIG-G1`, `SIG-G2`, `SIG-G3`, `SIG-G4`) and `no` for the 2 leading signals (`SIG-L1`, `SIG-L2`). The 4 retirement-eligible signals form the contract that the the downstream KM Governance work retirement-trigger protocol consumes.

5. **Trigger semantics are STABLE** — T-OP (operator-correction-count) / T-RW (rework-count) / T-CI (critical-incident-count) trigger definitions, measurement-window semantics, severity classifications will NOT change. Threshold values (3 / 2 / 1) are TUNABLE under standard governance protocol with operator approval per the `[CALIBRATE-AFTER-3]` discipline; the threshold values are not part of the stability commitment, but trigger SEMANTICS are.

6. **Cadence-derivation rule (tier → cadence binding) is STABLE** — the 3-tier mapping (`stable → 12mo`, `evolving → 6mo`, `emerging → 3mo`) is the contract. New tiers entering [`framework-catalog.md`](../specs/framework-catalog.md) extend (not replace) the mapping.

### Schema evolution policy — additive only

- New signals MAY be added to the catalog after ship. Existing signal IDs NEVER reassigned, NEVER renamed, NEVER removed.
- New triggers MAY be added (e.g., T-LD for adoption-decay) — additive.
- New ledger columns MAY be added (trailing the existing 10). Existing columns are immutable.
- Threshold values are TUNABLE (operator approval required via standard governance protocol) but trigger SEMANTICS are stable.
- New tiers entering `framework-catalog.md` MUST extend the cadence-derivation rule (§5); existing tier→cadence mappings cannot be reassigned.

### Breaking-change coordination

If a downstream consumer's Stage 5 surfaces an efficacy-schema gap (e.g., needs a signal not in the catalog OR needs a column not in the ledger), the consumer escalates **Tier 2 [SCOPE CHANGE]** per [`release-process.md § Inter-Stage Feedback Protocol`](../../release/governance/release-process.md) back to this framework's owner. Resolution paths:

1. Operator approves new signal/column addition; framework is amended in the consumer's release branch; schema-stability commitment honored (additive only).
2. Operator declines and consumer's Stage 5 finds alternative path.
3. Operator escalates to Tier 3 [PLAN REJECTION] if the consumer cannot proceed without breaking change.

Schema-stability constraint OVERRIDES downstream-consumer design convenience — if a breaking change is required, it is operator-authorized governance, not silent mutation.

---

## §11 Pilot Verification

### Ship state

At ship, the framework is published as this file plus the ledger at [`<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/practice-efficacy-ledger.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/practice-efficacy-ledger.md). The ledger contains **1 demo row** synthesized from SIG-G3 (operator-correction frequency) measurement on the `decision-discipline.md` framework's own scope — demonstrating the schema is operational without overcommitting.

The demo row records: practice `decision-discipline-framework`, signal `SIG-G3`, observation window 2025-11-24 to 2026-05-23 (180-day rolling at ship), measured value `0` (no operator corrections in observation log overlapping `(general-agent-behavior, pattern-cache-infrastructure)`), threshold band `good`, trigger fired `no`, review due `2026-08-23` (3-month cadence for `decision-discipline` registered as `tier: stable` at framework-catalog — note: `stable` derives to 12mo per §5, so review_due_at would actually be 2027-05-23; the 3-month value above is computed against the practice as a NEWLY-MEASURED-CADENCE for demo purposes — the ledger row text is the canonical reference).

### Deferred items at ship

| # | Item | Disposition | Trigger to act |
|---|---|---|---|
| F1 | `pipeline-event-log-schema.md` extension for `event_type: practice-efficacy` and `event_subtype: practice-failure` (SIG-G4 + T-CI evidence source) | DEFER to a later release | First actual incident attributed to a practice fires; at that point the operator co-decides whether to extend the schema or use manual annotation in payload field |
| F2 | Automated `check-practice-efficacy.sh` tool (computes per-practice signal values per release, batch-appends ledger rows) | DEFER (no scheduled release) | Operator decides automated efficacy reporting warrants tool implementation |
| F3 | Periodic `<OPERATOR_INSTANCE_ANALYSIS_PATH>/` efficacy reports (aggregated reporting consumer per §7 data-flow) | DEFER (no scheduled release) | Operator decides periodic reporting cadence is needed |
| F4 | `pmo-qa-auditor` reciprocal SKILL.md integration (KM scanning consumes SIG-G3) | DEFER (downstream) | a future Stage 5 decides integration scope |
| F5 | Calibration GitHub Issue auto-spawn (T-OP / T-RW / T-CI threshold validity) | TRIGGER at 3rd post-cutover release applying framework | Stage 13 Close auto-spawns per `[CALIBRATE-AFTER-3]` discipline |

### Stage 13 release-readiness checklist obligation

From the release after publication onward, Stage 13 Close spoke surfaces:

- Practices with cadence-due efficacy review (per §5 derivation against framework-catalog `last_reviewed`)
- Practices with fired triggers (T-OP / T-RW / T-CI) since the last release
- New ledger rows appended in the release window (audit-trail integrity check)

The operator renders disposition per surfaced practice — revise / refine / retire / accept-as-residual. Disposition is recorded in the release plan's verification-evidence section per standard Stage 13 discipline.

### Audit-trail integrity

The framework's audit-trail surfaces are:

1. **Ledger rows** — append-only record of measurements per practice per signal per window
2. **Framework-catalog `last_reviewed` date** — operator-attested last-review-completed marker (update on disposition)
3. **Stage 13 release-readiness checklist** — release-level surfacing of cadence-due / trigger-fired practices
4. **Trigger-fire pointers in ledger `source_artifact` column** — point to the originating evidence (observation log entry, pipeline-event-log row, git commit SHA range, gh issue comment) for re-verification

These four surfaces compose to produce a re-verifiable audit trail: any reader (operator, downstream consumer, future analysis report) can reconstruct WHY a trigger fired by reading the `source_artifact` pointer back to the originating evidence.

---

## Related references

- [`framework-catalog.md`](../specs/framework-catalog.md) — registry of all platform frameworks; this framework's `tier` column drives §5 cadence derivation
- [`architecture-overview.md`](../disciplines/architecture-overview.md) § Peer-Spec Concept Ownership — the concept index that points to this framework
- [`decision-discipline.md § 4`](../disciplines/decision-discipline.md) — Pattern Cache Infrastructure; SIG-G3 is the efficacy mirror of operator-correction promotion
- [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) — schema authority for `event_type: practice-efficacy` extension (deferred)
- [`design-artifact-standard.md`](design-artifact-standard.md) § 7 — Tier-A activation criteria for the 3 design artifacts embedded here (§3, §6, §7)
- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — R1 / R3 composition for Stage 5 cross-D consistency
- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1 placement model for this framework's standards/ location
- `pmo-qa-auditor` KM scanning — staleness scope; boundary in §9
- Drift-scope tooling (`health-check.sh` + `doc-link-maintenance.md` Check 14 / Check 15) — boundary in §9
- the downstream KM Governance work retirement triggers — hard downstream consumer; schema-stability commitment in §10

<!-- repo-integrity: allow-issue-ref -->
# Gate Criteria Specification

Defines three named gates across the triage lifecycle — Triage Readiness, Workflow Readiness, Release Readiness — with structured criteria for validation, automation routing, and self-repair.

**Relationship to the architecture stack:**
- [field-lifecycle-matrix.md](field-lifecycle-matrix.md) — defines field state per stage and structural gate requirements (Gates 1->2, 2->3, 3->4). Named gates **extend** these structural gates with metrics and judgment layers. They do not replace them.
- [stage-io-contracts.md](stage-io-contracts.md) — defines artifact deliverables per stage boundary. Gates validate field/anchor/artifact state; I/O contracts validate handoff completeness.
- [pipeline/](../../release/references/pipeline/) — Stages 1-3 §7 reference named gates by name. This file provides the structured definitions.
- `engineering/rules/release-process.md` — concise operating procedure references named gates per stage.
- [review-composition-framework.md § 3 Review Catalog + § 4 Review Map](../standards/review-composition-framework.md) — composes the gate criteria defined here into named composed reviews (RC-* IDs) and maps them to stage × posture cells. Gate criteria remain owned here; the framework references them as sub-components.

**Consumers:**
- Automated gate-validation tooling — filters by gate (e.g., `gate=G3`) and iterates criteria programmatically.
- Stage-gate evaluator — routes by check type: `structural` → auto-validate, `metrics` → compute, `judgment` → LLM-assess.
- Agents executing CER Claim phase — validate named gate criteria in addition to field-lifecycle-matrix structural gates.

---

## Schema

Each criterion uses a 5-field table:

| Field | Type | Purpose |
|-------|------|---------|
| **ID** | `G[gate]-[seq]` or `G-[stage-abbrev][seq]` | Stable identifier for programmatic reference. Numeric-gate format (G1-01 through G3-07) used for Stages 1-3 named gates. Stage-abbrev format (G-PR, G-EX, G-CL, G-BR) used for Stages 9/12/13 named gates + the cross-stage Bundle Refresh gate. |
| **Criterion** | String | Human-readable description of what is validated. |
| **Type** | Enum | Classification of what the criterion checks. Values: `field` (issue body field), `anchor` (state anchor — label, Projects field, status), `artifact` (deliverable — comment, file, sub-issue), `validation` (cross-issue or cross-system check). |
| **Check** | Enum | How the criterion is evaluated. Values: `structural` (deterministic — field presence, format match, state comparison), `metrics` (computed aggregate — ratio-based, threshold-compared, derived from structural criteria or GitHub state), `judgment` (requires interpretation — quality, specificity, actionability). |
| **Automation** | Enum | Who performs the check. Values: `auto` (Tier 1 — agent executes without human input), `recommend` (Tier 2 — agent evaluates and recommends, human confirms), `human` (Tier 3 — human-only judgment). Maps to pipeline automation tiers. |

### Inheritance Rules

Named gates inherit all structural checks from the corresponding [field-lifecycle-matrix.md](field-lifecycle-matrix.md) gate. Inherited criteria are **not duplicated** in the tables below — the named gate adds criteria beyond what the structural gate already requires.

| Named Gate | Inherits From | Relationship |
|---|---|---|
| Triage Readiness | Gate 1->2 (field-lifecycle-matrix.md) | Superset — adds judgment criteria to structural checks |
| Workflow Readiness | Gate 2->3 (field-lifecycle-matrix.md) | Superset — adds routing validation and management action checks |
| Release Readiness | Gate 3->4 (field-lifecycle-matrix.md) | Superset — adds dependency chain validation and scope assessment |
| Plan Review | Gate 8->9 + Gate 9->12 (field-lifecycle-matrix.md) | Superset — adds evidence-package and decision-record criteria to structural entry/exit checks |
| Execute Readiness | Gate 12->13 (field-lifecycle-matrix.md) | Superset — adds deployment-execution and verification criteria to structural transition checks |
| Close Readiness | Gate 13 Exit (field-lifecycle-matrix.md) | Superset — adds operational-deployment and verification-evidence criteria to structural close checks |

**Validation sequence:** Validate inherited structural gate first (field-lifecycle-matrix.md). If structural gate fails, named gate fails without evaluating additional criteria. If structural gate passes, evaluate named gate criteria below.

---

## Gate 1: Triage Readiness

*"Is there enough here to analyze?"*

**Stage boundary:** 1->2 (Intake -> Triage)
**Inherits:** Gate 1->2 from [field-lifecycle-matrix.md](field-lifecycle-matrix.md#gate-1-2-intake---triage)

**Template-awareness precondition (applies to all G1/G2/G3 structural runs).** Identify the issue's intake template (`improvement.yml` / `bug.yml` / `observation.yml`) via the Template Detection Logic block below **before** evaluating any structural criterion. The G1 criteria are written against the `improvement.yml` field set; running them one-size-fits-all against a mismatched template produces both error directions — false-positive failures (a structural check fires on a field the template renames or omits, e.g. `Priority`-vs-`Severity`) and false-negative passes (a template that legitimately lacks a field is bundled into a delivery milestone where that field is required downstream). Resolve per-template applicability from the criterion's `improvement | bug | observation` column triple (`req` / `adapt:<adapter-id>` / `n/a` / `conv`) and apply the named Adapter Block for any `adapt:` cell. Template-agnostic criteria (dependency-ref validity, cycle detection) are exempt — their checks do not reference template-specific field names.

| ID | Criterion | Type | Check | Automation | improvement | bug | observation |
|---|---|---|---|---|---|---|---|
| G1-01 | Title follows `[Category]: Description` format | field | structural | auto | `req` | `adapt:G1-01-Bug` | `adapt:G1-01-Obs` |
| G1-02 | Tier-branched: **(a) `improvement`-labeled** — Description field is actionable, not just observation. **(b) `observation`-labeled** — the three required `observation.yml` fields (what is missing / what good looks like / which file or section) contain enough signal that a Triage agent could draft a Proposal that itself meets G1-02 branch (a) post-promotion. | field | judgment | recommend | `req` (improvement branch) | `adapt:G1-02-Bug` | `req` (observation branch) |
| G1-03 | Evidence contains >=1 evidence-labeled claim | field | structural | auto | `req` | `req` | `n/a` (no Evidence field) |
| G1-04 | Proposed Change is specific (names files or protocols) | field | judgment | recommend | `req` | `n/a` (bug body is Reproduction Steps + Expected/Actual) | `n/a` (no Proposed Change field) |
| G1-05a | Every AC bullet starts with a verifiable verb (verify/check/confirm/assert/ensure/validate), OR names a file-path+state predicate with a backtick-wrapped path and a `contains`/`includes`/`has` state verb, OR starts with `predicate:` | field | structural | auto | `req` | `adapt:G1-05-Bug` | `n/a` (no AC field; conversion required) |
| G1-05b | AC overall are verifiable beyond the structural verb check — no placeholder leakage (unreplaced `<...>` slots), no commented-out bullets, each predicate names an observable state | field | judgment | recommend | `req` | `adapt:G1-05-Bug` | `n/a` |
| G1-06 | Priority set in issue body per improvement.yml Priority field (P1–P4) — label-based priority is NOT expected | field | structural | auto | `req` | `adapt:G1-06-Bug` | `n/a` (no Priority field) |
| G1-07 | Status = Proposed, Stage = 1-Intake | anchor | structural | auto | `req` | `req` | `req` |
| G1-08 | A fresh Claude Code session loaded with CLAUDE.md + `core/rules/` can implement the ticket without asking clarifying questions about terminology, cross-issue references, or scope boundaries | field | judgment | recommend | `req` | `req` | `req` |
| G1-09 | Intake-tier label (`improvement` / `bug` / `observation`) matches body template structure per the Template Detection Logic block below | validation | structural | auto | `req` | `req` | `req` |

**Applies-to column triple semantics:** `req` = criterion applies; check field per template schema. `adapt:<adapter-id>` = criterion applies but field is lexically/semantically translated per the Adapter Block below. `n/a` = criterion does not apply (the field does not exist on this template). `conv` = criterion is a Bundle prerequisite; issue must be converted to `improvement.yml` before this gate evaluates (raised at Stage 3 Phase A1 per the Template-Conversion Rule in § Gate 3).

### Template Detection Logic (consumed by G1-09 + by all template-aware gates)

Step 1 (primary): Read the intake-tier label.
  - Set of intake-tier labels: {`improvement`, `bug`, `observation`}.
  - If exactly one match: `label_template` = that label.
  - If zero or >1 matches: emit `G1-09 FAIL: 0 or >1 intake-tier labels` and route to self-repair (apply correct single label).

Step 2 (confirmation): Infer template from body markers.
  - Body marker patterns:
    - `### Severity` AND `### Reproduction Steps` ⇒ inferred = `bug`
    - `### Priority` AND `### Category` AND `### Description` ⇒ inferred = `improvement`
    - `### What is missing?` AND `### What does good look like?` ⇒ inferred = `observation`
    - none of the above match exclusively ⇒ inferred = `ambiguous`

Step 3 (reconcile):
  - If `label_template == inferred`: `template = label_template`; G1-09 PASS.
  - If `label_template != inferred` AND `inferred != ambiguous`: G1-09 FAIL with `label=<X>, body=<Y>` payload.
  - If `inferred == ambiguous`: G1-09 PASS but flag for operator review (body may have been edited post-template-rendering).

**Body-marker uniqueness verification:** `### Severity` is unique to bug.yml (improvement and observation lack the field). `### Reproduction Steps` is unique to bug.yml. `### What is missing?` is unique to observation.yml. `### Priority` is present in improvement.yml only; `### Priority` + `### Category` is doubly redundant for confirmation.

**Consumer integration:** This detection block is the canonical template-detection primitive consumed by: (1) Gate-running scripts (existing automated validation and stage-gate evaluator consumers) — call template-detect before iterating criteria; apply per-template applicability per the matrix. (2) CER Claim agents (Stage 1/2/3 hub-spoke) — same primitive. (3) Stage 3 Phase A1 (Bundle pre-bind) — same primitive; observation result triggers Template-Conversion Rule. (4) New G1-09 row — same primitive; mismatch is the FAIL signal.

### Gate 1 Adapter Blocks (inline lexical/semantic translation)

**Adapter G1-01-Bug:** bug.yml title prefix is the literal string `[Bug]:` (per `bug.yml` template line 3 `title: "[Bug]: "`); G1-01's `[Category]:` check accepts `[Bug]:` as canonical.

**Adapter G1-01-Obs:** observation.yml title prefix is the literal string `[Observation]:` (per `observation.yml` template line 3); G1-01's `[Category]:` check accepts `[Observation]:` as canonical.

**Adapter G1-02-Bug:** bug.yml has no Description field; G1-02 evaluates against the conjunction of `### Reproduction Steps` + `### Expected Behavior` + `### Actual Behavior` (collectively "the bug narrative"). The narrative is actionable iff a fresh agent can reproduce + observe expected vs. actual. Label-missing branch unchanged.

**Adapter G1-05-Bug:** bug.yml AC follows the bug-narrative AC pattern (per `bug.yml` template lines 78-84): "reproduction steps no longer trigger actual behavior; expected behavior observed." G1-05a verb-list accepts the literal phrase pattern `reproduction steps no longer trigger actual behavior` OR `running reproduction steps produces expected behavior` as a structurally-valid AC bullet. Other G1-05a clauses (verb-first / file-path+state / explicit predicate) continue to apply unchanged.

**Adapter G1-06-Bug:** bug.yml has `### Severity` (P1-Blocker / P2-Material / P3-Annoyance / P4-Cosmetic) in lieu of `### Priority` (P1-Urgent / P2-High / P3-Medium / P4-Low). Semantic mapping: P-level digit (1-4) is canonical; the Severity P-level satisfies G1-06. A single template-agnostic detector covers both field names — match `(Priority|Severity)[\s\n]+P[1-4]` (multi-line-aware so the P-level on the line following the heading is captured). The P-level digit, not the field name or qualifier word, is the canonical satisfier.

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G1-01 | Title missing category prefix | Auto-fix: prepend `[Category]: ` from category field. If category absent, flag for author. |
| G1-02 (improvement) | `improvement`-labeled, Description is observational | Return to author: "Description states an observation but not an actionable change. Reframe as what should change and why. If this issue is a placeholder gap-capture (no actionable change yet), re-author as `observation.yml` instead." |
| G1-02 (observation) | `observation`-labeled, ≥1 of the three required fields (what is missing / what good looks like / which file or section) is missing, vague, or non-promotable | Return to author: "Observation-tier fields must contain enough signal that a Triage agent could draft a Proposal whose Description would itself pass G1-02 branch (a). Identify which field is non-promotable: [field name]. Promotability test: would a Proposal-tier Description drafted from these three fields be actionable?" |
| G1-02 (label missing) | Neither `observation` nor `improvement` label is present (or both are present) | Return to author or triage agent: "Issue lacks a single primary intake-tier label. Apply `observation` OR `improvement` per `pipeline/stage-01-intake.md` §5 Routing + `intake-style-guide.md` §2 (5-test rule)." |
| G1-03 | No evidence labels | Return to author: "Evidence section needs at least one `[SOURCE]`, `[INFERRED]`, or `[CONTEXT]` label." |
| G1-04 (under-specified) | Proposed Change names no file or protocol affected — the WHAT is missing | Return to author: "Proposed Change must name the specific file(s) or protocol(s) affected." |
| G1-04 (over-specified) | Proposed Change prescribes mechanism — algorithm, data structure, implementation pattern, pseudocode, or line-level surgical directive — committing the HOW prematurely | Return to author with the canonical WHAT-not-HOW remediation in [`intake-style-guide.md`](../../release/references/how-to/intake-style-guide.md) §5 (cite the specific Stage 5-column item; offer re-author-in-WHAT **or** `[ASSUMPTION – CONFIRM]`-defer-to-Stage-5). |
| G1-05a | AC bullet fails structural verb/predicate check | Return to author: "AC bullet `[quoted bullet]` does not match a G1-05a pattern. Rewrite as one of: (a) verb-first — 'Verify that `file/section` contains state Y', or (b) file-path+state — '`file/section` contains state Y', or (c) explicit predicate — 'predicate: <expression>'." |
| G1-05b | AC judgment failure (semantic vagueness, placeholder leakage, or commented-out bullets) | Return to author with specific vague-language call-out, unreplaced-`<...>`-slot identification, and an example rewrite matching a G1-05a pattern. |
| G1-06 | Priority missing | Return to author: "Set priority P1-P4 in the issue body per improvement.yml Priority field. Do NOT apply a priority label — label-taxonomy.md tracks priority in the body." |
| G1-07 | Anchors incorrect | Auto-fix: set Status = Proposed, Stage = 1-Intake, apply `status: proposed` label. |
| G1-08 | Pickup-blocking undefined terms | Agent scans issue body for jargon, abbreviations, cross-issue references, and Skills-Map terminology. A term is "undefined" if it lacks (a) an inline parenthetical definition, (b) a `#N` issue reference, or (c) a markdown link to a governance doc that defines it. If undefined count > 3, return to author: "G1-08: The following terms would require a fresh Claude Code session to ask clarifying questions. Define inline or cite governance: [list]." |
| G1-09 | Label-body mismatch detected | Per the Template Detection Logic block: emit `G1-09 FAIL: label=<X>, body=<Y>` payload. Two remediation paths (operator decision): **(a) Relabel** — change intake-tier label to match the body's structural template; **(b) Rewrite body** — rewrite body to match the existing label's template schema. For zero / multiple intake-tier labels: apply correct single intake-tier label per `pipeline/stage-01-intake.md` § Routing + `intake-style-guide.md` § 2 (5-test rule). |

---

## Gate 2: Workflow Readiness

*"Has this been enriched enough to enter the workflow?"*

**Stage boundary:** 2->3 (Triage -> Bundle)
**Inherits:** Gate 2->3 from [field-lifecycle-matrix.md](field-lifecycle-matrix.md#gate-2-3-triage---bundle)

| ID | Criterion | Type | Check | Automation | improvement | bug | observation |
|---|---|---|---|---|---|---|---|
| G2-01 | Priority validated against full backlog context | field | judgment | recommend | `req` | `adapt:G2-01-Bug` | `conv` (must convert before bundling — Priority field missing) |
| G2-02 | Category label matches content | anchor | judgment | recommend | `req` | `req` (auto-applied `bug` label) | `conv` (observation has no category) |
| G2-03 | No unresolved duplicates or subsumption conflicts | validation | structural | auto | `req` | `req` | `req` |
| G2-04 | Dependencies reference valid open issues or "None" | field | structural | auto | `req` | `n/a` (no Dependencies field in bug.yml) | `n/a` (no Dependencies field) |
| G2-05 | Cluster label assigned | anchor | structural | auto | `req` | `req` | `req` |
| G2-06 | Decision Date set in GitHub Projects Date field (queryable via Projects API, not parsed from comment text) | anchor | structural | auto | `req` | `req` | `req` |
| G2-07 | Triage decision comment posted | artifact | structural | auto | `req` | `req` | `req` |
| G2-08 | Management-action items routed (if applicable) | validation | judgment | recommend | `req` | `req` | `req` |
| G2-09 | No unflagged synthesis-candidate pairs against the open Proposed/Approved set. Candidate pair = candidate issue + any open Proposed/Approved issue sharing (a) `cluster:*` label AND (b) ≥1 explicit cross-reference edge (Dependencies-field reciprocity OR shared upstream parent `#N` cited in both Dependencies fields). For each candidate pair: routing decision recorded (fold / decompose-into-roadmap / keep-separate-with-rationale / defer-for-coordination). Per Similarity Composite-Signal Detection block below. | validation | judgment | recommend | `req` | `req` | `req` |
| G2-10 | Size-driven decomposition routing recorded when `size:XL` label applied. For `size:XL`: routing decision recorded (decompose-into-slice / split-into-sub-issues / approve-as-is-with-risk-note / defer-for-pre-bundle-analysis). For `size:L`: informational flag only (no routing decision required at G2-10; carry forward to G3-09). For `size:M` / `size:S` / `size:XS`: exempt. | validation | judgment | recommend | `req` | `req` | `req` |
| G2-11 | Decomposition-review routing recorded when ANY oversize predicate matches (COMPOSITE-OR: **P1** `size:XL` label applied OR **P2** issue body cites declared decomposition hooks — at least 1 occurrence of literal `Decomposition hook` OR enumerated scope-split pattern `(a) ... (b) ... (c)` inside Notes/Proposed Change sections OR **P3** AC count ≥ 7 OR Affected Files count ≥ 5). For each matching predicate set: routing decision recorded per the 3-outcome enum — **kept-as-one with rationale** (operator records 1-line rationale naming the predicate(s) that fired + why issue is genuinely atomic despite firing) / **split per fission protocol** ( — invokes [fission-convention.md](../../release/references/protocols/fission-convention.md) Procedure Steps 1-4: parent body Fissions-into annotation + per-child creation + Fission Comment + parent close-as-fissioned OR convert-to-tracking) / **escalate** (Tier 2 [SCOPE CHANGE] per [`release-process.md`](../../release/governance/release-process.md) § Inter-Stage Feedback Protocol — issue stays in `status: proposed` until operator-rendered disposition). G2-11 SUBSUMES G2-10 when its predicate fires (one routing decision under G2-11 — NOT one routing under G2-10 plus a second routing under G2-11). G2-11 PASSES trivially when no predicate fires. Per Composite-OR Oversize Predicate block below. | validation | judgment | recommend | `req` | `req` | `req` |

### Composite-OR Oversize Predicate (referenced from G2-11 / G3-12 criterion bodies)

A candidate issue triggers oversize-decomposition review when ANY of the following predicates matches:

**P1 — `size:XL` label applied.** Verifiable: `gh issue view N --json labels` filtered for `size:XL`. Subsumes existing G2-10 baseline. Backwards-compatible.

**P2 — Body cites declared decomposition hooks.** At least 1 occurrence of literal `Decomposition hook` OR enumerated scope-split pattern `(a) ... (b) ... (c)` inside Notes/Proposed Change sections. Verifiable: `grep -ci "decomposition hook\|scope may split into\|sub-scopes\?:\s*(a)\|(a)\s*[^)]*\s*(b)\s*[^)]*\s*(c)"` over issue body. Catches the ** canonical-evidence-instance gap** —  body declared `Decomposition hook for Triage: scope may split into (a)/(b)/(c)` yet was `size:M`. G2-10 missed it.

**P3 — AC count ≥ 7 OR Affected Files count ≥ 5.** Verifiable: `grep -c "^- \[ \]"` (AC list checkboxes) OR `grep -cE "^\\\`?(\\\.claude|pmo-platform|projects)/" Affected\\\ Files\\\ section` (file pointer lines) over issue body. Catches silent-mis-size — a ticket labeled `size:M`/`size:L` whose AC/file fan-out exposes oversize. Calibrate-after-3 MEDIUM-confidence thresholds (`7` / `5` chosen from current-state median+1σ).

**Tie-break (operator override):** If predicate fires but operator judges the ticket genuinely atomic (e.g., exhaustive testing AC list rather than scope multiplicity), operator records `kept-as-one with rationale` — predicate firing gates a decision, does not auto-route to split.

**Detection command (reproducible):**

```bash
# Composite-OR oversize predicate check at triage/bundle time
ISSUE=<N>
BODY=$(gh issue view $ISSUE --json body --jq '.body')
LABELS=$(gh issue view $ISSUE --json labels --jq '.labels[].name')
P1=$(echo "$LABELS" | grep -c '^size:XL$')
P2=$(echo "$BODY" | grep -ciE 'decomposition hook|scope may split into|sub-scopes?:.*\(a\)|\(a\)[^)]+\(b\)[^)]+\(c\)')
P3_AC=$(echo "$BODY" | grep -c '^- \[ \]')
P3_FILES=$(echo "$BODY" | grep -cE '^`?(\.claude|pmo-platform|projects)/')
# G2-11/G3-12 predicate fires when (P1 ≥ 1) OR (P2 ≥ 1) OR (P3_AC ≥ 7) OR (P3_FILES ≥ 5)
```

### Roadmap-Cascade Validation (referenced from G3-13 criterion body)

**RETIRED (ADR-012, 2026-06-02).** Roadmap instances are operator-local, so in-repo cascade detection no longer runs. The `G3-13` criterion is retained as a numbered tombstone in the Gate 3 table below; the former enumerate / branch / classify procedure and detection script are removed.

### Gate 2 Adapter Blocks

**Adapter G2-01-Bug:** validate Severity (not Priority) against full backlog context — semantic equivalence per Adapter G1-06-Bug (P-level digit canonical).

**G2-04 augmentation — Native-Dep Mirror (post-validation):**

Post-validation, the Stage 2 spoke fires the A3.5 native-mirror substep per [`pipeline/stage-02-triage.md` § Native-Dep Mirror](../../release/references/pipeline/stage-02-triage.md). The mirror syncs body `FS+0d` dependencies to native `blocked-by`. A3.5 is NOT gate-blocking — G2-04 PASS/FAIL is determined solely by the validation criterion in the table row above; A3.5 is an additive sync side-effect that fires once the gate has passed. Native-mirror failures (API errors, scope issues, cap hits) surface in the A6 triage summary for operator awareness but do not block Phase B verdict. Per [`ticket-information-architecture.md § Native Dependencies`](../../release/references/specs/ticket-information-architecture.md#native-dependencies). Cutover discipline: the native-dep mirror applies to all triaged issues going forward.

**Similarity Composite-Signal Detection (referenced from G2-09 / G3-08 criterion bodies):**

A candidate issue triggers similarity-pair detection when, for any open Proposed/Approved/Bundled issue B:

1. **Cluster axis (required).** Candidate and B share at least one `cluster:*` label per [label-taxonomy.md § Cluster Labels](../specs/label-taxonomy.md).
2. **Edge axis (required — either OR).** At least one of:
   - **Reciprocity:** Candidate's Dependencies field cites `#B` OR B's Dependencies field cites `#<candidate>`.
   - **Shared parent:** A third issue `#P` cited in BOTH Candidate's Dependencies and B's Dependencies.

Both axes required. Pure cluster-label match without edge axis is NOT a candidate pair (avoids false-positive flood on hub clusters like `cluster: process-protocol`). Pure edge axis without cluster match is downgraded to advisory (cross-cluster coordination is common and rarely indicates synthesis).

**Detection command (reproducible):**

```bash
# Candidate similarity-pair search at triage time
CAND=<candidate-issue>
CLUSTER=$(gh issue view $CAND --json labels --jq '.labels[] | .name | select(startswith("cluster:"))')
gh issue list --search "label:\"$CLUSTER\" is:open" --json number,labels,body --jq \
  '.[] | select(.number != '$CAND') | {n: .number}'
# Cross-check each result against candidate Dependencies field reciprocity + shared parent
```

Soft-language exclusion: "related to" / "similar to" / "see also" in body text is NOT an edge axis hit — the field must be the Dependencies section, not free-form prose.

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G2-01 | Priority not validated | Present priority comparison against backlog to operator for confirmation or adjustment. |
| G2-02 | Category mismatch | Recommend category correction to operator based on issue content analysis. |
| G2-03 | Unresolved duplicates | Flag duplicate candidates with similarity rationale for operator resolution (merge, subsume, or dismiss). |
| G2-04 | Invalid dependency refs | Flag invalid references: closed/deleted issues, self-references, circular chains. List valid alternatives. |
| G2-05 | Cluster label missing | Recommend cluster from category taxonomy. Apply if unambiguous; flag if multiple candidates. |
| G2-06 | Decision Date not set in Projects Date field | Auto-set the GitHub Projects Date field per `release/references/pipeline/stage-02-triage.md` § Phase B B2a (forcing-function and failure-handling block) at CER Resolve. On Projects API failure: gate fails; CER Resolve produces a documented failure outcome (does not silently auto-pass). |
| G2-07 | No triage comment | Draft triage decision comment from analysis results for posting. |
| G2-08 | Routing incomplete | Present unrouted management-action items to operator with recommended routing targets. |
| G2-09 | Candidate pair detected with no routing decision | Surface candidate pair to operator with detection evidence (cluster overlap, edge axis specifics). Present 4 routing options (A fold / B decompose-into-roadmap / C keep-separate-with-rationale / D defer-for-coordination); operator renders. Record decision in Triage decision comment per § Phase B Output State Semantics + apply outcome-specific labels per [subsumption-convention.md](../../release/references/protocols/subsumption-convention.md). |
| G2-10 | size:XL ticket with no decomposition-routing decision | Surface size:XL ticket to operator with decomposition options (A decompose-into-slice / B split-into-sub-issues / C approve-as-is-with-risk-note / D defer-for-pre-bundle-analysis); operator renders. Record decision in Triage decision comment + ticket body Notes/Risks per outcome. size:L cross-stage informational flag posted as advisory comment; no required decision. |
| G2-11 | Oversize predicate (P1 `size:XL` OR P2 declared-decomposition-hook OR P3 AC ≥ 7 OR P3 files ≥ 5) fired with no 3-outcome routing decision recorded | Surface predicate-firing evidence to operator with the matched predicate(s) and the 3-outcome enum (A kept-as-one with rationale / B split per [fission-convention.md](../../release/references/protocols/fission-convention.md) / C escalate per Tier 2 [SCOPE CHANGE]); operator renders. Record decision in Triage decision comment per § Phase B Output State Semantics. On SPLIT outcome: invoke fission-convention.md Procedure Steps 1-4 (parent body Fissions-into annotation + per-child creation + Fission Comment + parent close-as-fissioned OR convert-to-tracking per its D-ParentDisposition). On KEPT-AS-ONE outcome: record 1-line rationale naming the predicate(s) that fired. On ESCALATE outcome: flag hub for operator decision per Inter-Stage Feedback Protocol Tier 2; issue stays in `status: proposed` until operator-rendered disposition. |

---

## Gate 3: Release Readiness

*"Can this be responsibly assigned to a release?"*

**Stage boundary:** 3->4 (Bundle -> Planning)
**Inherits:** Gate 3->4 from [field-lifecycle-matrix.md](field-lifecycle-matrix.md#gate-3-4-bundle---planning)

**Body-compliance precondition for the `status: bundled` transition.** Before transitioning any issue from a pre-bundled status (`status: proposed` / `status: approved`) to `status: bundled`, re-run the G1 (Triage Readiness) and G3 structural checks against the issue **body** — do not infer compliance from label state. Labels reflect intent, not body-level compliance: a `status: approved` label does not imply the body satisfies G1-01..G1-08, and a `[Category]:` title prefix does not imply the Priority / Affected Files / Acceptance Criteria fields exist. Verifying at bundle-time is strictly cheaper than discovering a body defect mid-Stage-4 Planning, which forces a rollback and re-triage. This precondition has highest value on the cases where label-to-body drift is most likely:

- multi-issue bundling operations (several issues bound at once);
- cross-milestone routing decisions;
- bundling of issues whose bodies may have aged since their last G1 evaluation;
- any transition that skips the standalone `status: approved` state (`status: proposed` → `status: bundled` directly);
- any bundling that pulls an `observation`-tier issue into a delivery milestone (the observation template cannot satisfy improvement-tier G1 — conversion per the Template-Conversion Rule below is required first).

Minimum re-check set when the precondition applies: **G1-01** (title-prefix format), **G1-03** (≥1 evidence-labeled claim, per-template per the Adapter/applicability rules), **G1-06** (Priority/Severity present, multi-line-aware per Adapter G1-06-Bug), **G3-01** (every dependency reference in a compatible state), **G3-02** (no circular dependency chain — construct the intra-bundle graph and traverse it, do not merely scan). Single-issue milestone moves, sub-task decompositions within an already-bundled parent, and operator-explicit "skip with rationale" are out of scope (defer to the Stage 4 Planning gate).

| ID | Criterion | Type | Check | Automation | improvement | bug | observation |
|---|---|---|---|---|---|---|---|
| G3-01 | All dependencies in compatible states (Approved/Bundled/Done) | validation | structural | auto | `req` | `req` | `conv` |
| G3-02 | No circular dependency chains | validation | structural | auto | `req` | `req` | `conv` |
| G3-03 | Affected files identified (at least directional) | field | structural | auto | `req` | `req` | `conv` (no Affected Files field) |
| G3-04 | Scope is implementation-ready (specific enough for planning) | field | judgment | recommend | `req` | `req` | `conv` |
| G3-05 | AC are measurable (can be verified in Stage 7/8) | field | judgment | recommend | `req` | `adapt:G3-05-Bug` | `conv` (no AC field) |
| G3-06 | No blocking issues in incompatible states | validation | structural | auto | `req` | `req` | `conv` |
| G3-07 | For every dependency edge `#A → #B` declared on an in-bundle issue, milestone-position(A's milestone) ≥ milestone-position(B's milestone), where milestone-position is computed deterministically per the Milestone-Position Resolution algorithm below. Edges registered in the candidate milestone's `## Dependency Exceptions` block PASS as governed exceptions; unregistered violating edges FAIL. | validation | structural | auto | `req` | `req` | `conv` |
| G3-08 | No unflagged synthesis-candidate pairs within the candidate bundle. Pair detection per Similarity Composite-Signal Detection block in § Gate 2. Each in-bundle pair: routing decision recorded in bundle rationale comment (fold / decompose-into-roadmap / keep-separate-with-rationale / defer-for-coordination). G3-08 PASSES trivially when bundle has 0 candidate pairs. Cross-bundle pairs (one issue in bundle, one outside) are advisory at G3-08; their primary surface is G2-09 at triage time. | validation | judgment | recommend | `req` | `req` | `req` |
| G3-09 | For every `size:XL` issue in candidate bundle: routing decision recorded in bundle rationale comment (decompose-into-slice / split-into-sub-issues / approve-as-is-with-risk-note / defer-for-pre-bundle-analysis). For every `size:L` issue with cross-stage scope (issue body references ≥2 distinct pipeline stages per `release/references/pipeline/stage-*.md` filenames): informational flag in bundle rationale, no blocking. Issues without a `size:*` label trigger G3-09 FAIL with self-repair `Apply size label per label-taxonomy.md before bundling.` G3-09 PASSES trivially when bundle has 0 `size:XL` issues and all sized issues meet routing-decision recording. | validation | judgment | recommend | `req` | `req` | `req` |
| G3-10 | Release Class declared in milestone description per the taxonomy. After Phase B3, grep `^## Release Class$` AND `^\*\*Class:\*\*` against milestone description (`gh api repos/<owner>/pmo-platform/milestones/<N> --jq .description`). Class value MUST be one of the 4-value enum: `routine` / `novel` / `cross-cutting` / `hotfix`. Non-empty `Rationale` sub-field REQUIRED. See release-class-taxonomy.md for canonical schema + per-class differentiation matrix (engagement density / review depth / Stage 5 activation bias / Stage 13 outcome-window). Class is orthogonal to `delivery_approach` (Scrum/Kanban/Waterfall) and orthogonal to Autonomy Tier (per-action). **Cutover discipline:** Release Class declaration is required for all milestones going forward. | artifact | structural | auto | `req` | `req` | `req` |
| G3-11 | Release Outcome Statement heading present in milestone description per the template. After Phase B3, grep `^### Release Outcome Statement$` against milestone description (`gh api repos/<owner>/pmo-platform/milestones/<N> --jq .description`). Non-blocking advisory — failure logs to `core/hooks/deploy-check-warn-log.jsonl` and bundle proceeds. See release-outcome-statement-template.md for canonical empty-shape (REQUIRED AFTER + BEFORE; OPTIONAL Actor(s) + Success Indicator). **Cutover discipline:** The Release Outcome Statement heading is required for all milestones going forward. | artifact | structural | auto-advisory | `req` | `req` | `req` |
| G3-12 | For every in-bundle issue: decomposition-review 3-outcome routing recorded in bundle rationale comment when ANY oversize predicate matches (COMPOSITE-OR per § Composite-OR Oversize Predicate block: **P1** `size:XL` label OR **P2** declared decomposition-hook in body OR **P3** AC count ≥ 7 OR file count ≥ 5). Routing enum: kept-as-one with rationale / split per [fission-convention.md](../../release/references/protocols/fission-convention.md) / escalate per Tier 2 [SCOPE CHANGE]. G3-12 is the drift-backstop for G2-11 — catches issues whose AC/file fan-out grew post-Triage. Issues that already routed at G2-11 (Triage) pass G3-12 trivially unless body has materially changed since Triage. G3-12 SUBSUMES G3-09 when its predicate fires (the 3-outcome enum replaces the 4-option G3-09 enum: decompose-into-slice → split; split-into-sub-issues → split; approve-as-is-with-risk-note → kept-as-one; defer-for-pre-bundle-analysis → escalate). G3-12 PASSES trivially when bundle has 0 issues matching any oversize predicate. **Cutover discipline:** Applies to all releases going forward.
| G3-13 | **RETIRED (ADR-012, 2026-06-02).** Roadmap-cascade validation de-scoped: roadmap instances are operator-local, so in-repo cascade detection no longer applies. Retained as a numbered tombstone so cross-references resolve. | - | - | - | - | - | - |

### Gate 3 Adapter Blocks

**Adapter G3-05-Bug:** AC measurability is satisfied by either (a) the standard verifiable-AC pattern OR (b) the bug-narrative AC pattern (per Adapter G1-05-Bug — "reproduction steps no longer trigger actual behavior; expected behavior observed").

### Template-Conversion Rule

An issue with the `observation` intake-tier label cannot have the `status: bundled` label applied. Before bundling, the issue body must be rewritten in `improvement.yml` schema (all required improvement.yml fields populated) and the intake-tier label must transition `observation` → `improvement` atomically with the body rewrite. Title prefix updates from `[Observation]: ...` to `[Category]: ...` per the chosen improvement.yml Category.

**Enforcement surface:** Stage 3 Phase A1 (Bundle entry). Phase A1 reads candidate-issue labels before evaluating G3 criteria; any candidate with `observation` label halts with the failure signal `BUNDLE-BLOCKED: observation-template requires conversion`.

**Conversion path:** route candidate back to Stage 2 Triage as a "promote observation" sub-step:
1. Triage agent re-runs G1-02 observation-branch promotability test;
2. On promotability PASS: Triage agent drafts improvement.yml body from the 3-field observation;
3. Operator approves the draft;
4. Body is rewritten + label transitions `observation` → `improvement` + title prefix updates;
5. Issue re-enters G1 evaluation under improvement-template applicability.

**Out-of-conversion paths (operator decisions):**
- **(A) Drop bundle binding:** issue remains `observation` label, milestone removed (issue stays open for future re-triage). Aligns with the least-destructive disposition pattern — preserves issue identity.
- **(B) Operator override:** issue is force-bundled with `[ASSUMPTION – CONFIRM]` markers on missing improvement.yml fields; operator commits to filling them at Stage 4 Planning. Override is recorded on the Milestone description's deviation log per [`release-process.md`](../../release/governance/release-process.md) § Inter-Stage Feedback Protocol Tier 2.

**Retroactive applicability:** The 2026-05-11 audit applied this rule retroactively to 5 observations ( /  /  /  /  — all promoted to improvement.yml bodies before bundling per the audit). Codifying the rule prevents the next round from depending on audit-style retroactive cleanup.

**Milestone-Position Resolution algorithm (referenced from G3-07 criterion body):**

1. **Override (primary):** If milestone description contains a `position: <integer>` line, use that integer.
2. **due_on (secondary):** Otherwise, sort milestones by `due_on` ascending (nulls last). Position = ordinal in the sorted list.
3. **Number (fallback):** Otherwise (for null `due_on`), sort by milestone `number` ascending. Position = ordinal in the sorted list.

Within a single position-equivalence-class (same `due_on` or same `position:` value), edges between members are treated as "same milestone" → G3-07 PASSES trivially (no cross-milestone-sequence concern within a single bundle). Same-milestone edges PASS by definition. When B's milestone is closed AND B's status is Done, the edge is annotated `[RESOLVED]` (not a violation). When B has no milestone (unbundled), G3-07 FAILS (cannot validate sequence).

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G3-01 | Dependency in incompatible state | List dependencies and their current states. Recommend: bundle the dependency, escalate priority, or remove dependency link. |
| G3-02 | Circular dependency detected | Visualize cycle (A -> B -> C -> A). Recommend: break weakest link or merge issues. |
| G3-03 | Affected files not identified | Flag as incomplete for planning. Recommend: Defer until files identified, or accept with `[ASSUMPTION – CONFIRM]` marker. |
| G3-04 | Scope too vague for planning | Return to triage for scope refinement. Recommend: add specific file/protocol targets to Proposed Change. |
| G3-05 | AC not measurable | Return to triage for AC refinement. Recommend: rewrite AC as assertions verifiable against file content or system state. |
| G3-06 | Blocking issue in incompatible state | List blocking issues and their states. Recommend: resolve blocker first, adjust bundle sequence, or remove from bundle. |
| G3-07 | Edge violates milestone-sequence inequality without exception registration | List violating edges with source/target milestone positions and gap. Offer remediation menu: (a) bundle target into source milestone, (b) re-sequence source to later milestone, (c) remove dependency link, (d) register exception in milestone description's `## Dependency Exceptions` block with rationale + authorizer + date. |
| G3-08 | In-bundle candidate pair with no routing decision | Surface in-bundle pair to operator with detection evidence. Present 4 routing options (A fold / B decompose-into-roadmap / C keep-separate-with-rationale / D defer-for-coordination); operator renders. Record decision in bundle rationale comment + ticket bodies per outcome. Cross-bundle pairs surfaced as advisory; primary surface is G2-09. |
| G3-09 | size:XL ticket in bundle with no decomposition-routing decision OR ticket missing size:* label | Surface size:XL to operator with decomposition options; operator renders. Record in bundle rationale comment. For unsized tickets: return to Triage with "Apply size label per label-taxonomy.md before bundling" self-repair. size:L cross-stage informational flag posted to bundle rationale; no required decision. |
| G3-10 | Release Class heading missing from milestone description, OR Class value outside 4-value enum, OR Rationale sub-field empty | Author `## Release Class` heading with `Class:` field (value from `routine` / `novel` / `cross-cutting` / `hotfix` enum) + non-empty `Rationale` sub-field per release-class-taxonomy.md § 2. PATCH milestone description via `gh api repos/.../milestones/<N> -X PATCH -f description=...`. Auto-mode posture: structural-required; bundle blocked until satisfied. Pre-cutover-or-exempt releases: no action — Class declaration is grandfathered as inferable from milestone scope. |
| G3-11 | Release Outcome Statement heading missing from milestone description | Author the heading + REQUIRED AFTER + BEFORE paragraphs per release-outcome-statement-template.md class-varying shape table; PATCH milestone description via `gh api repos/.../milestones/<N> -X PATCH -f description=...`. Warn-mode posture: log advisory + bundle proceeds. Pre-cutover-or-exempt releases: no action — existing `## Goal` / `**Goal (AFTER/BEFORE):**` form is grandfathered for read-purposes (Stage 9 G-PR7 + Stage 13 QC4-06 accept the sibling form). |
| G3-12 | In-bundle issue matches oversize predicate (P1 / P2 / P3) with no 3-outcome routing decision recorded in bundle rationale comment | Surface predicate-firing evidence to operator with the matched predicate(s) per § Composite-OR Oversize Predicate. Present the 3-outcome enum (A kept-as-one with rationale / B split per [fission-convention.md](../../release/references/protocols/fission-convention.md) / C escalate per Tier 2 [SCOPE CHANGE]); operator renders. Record decision in bundle rationale comment. On SPLIT outcome AT BUNDLE TIME: Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol — re-bundle with fission-children replacing parent (children re-enter Stage 2 Triage per fission-convention.md Re-triage State; parent close-or-convert per its D-ParentDisposition). On KEPT-AS-ONE: record 1-line rationale. On ESCALATE: return to operator for priority/capacity re-discussion, defer to later release, explicit override-with-rationale, or downstream re-Triage with refined scope. |
| G3-13 | RETIRED (ADR-012): roadmap-cascade validation de-scoped; roadmap instances operator-local. | No self-repair action - the criterion no longer fires. |

### Cross-Stage Decomposition Coverage (per AC #5)

The platform enforces decomposition review at three distinct altitudes — intake-altitude (when authored), Triage/Bundle-altitude (when Approved/Bundled), and Engineering-altitude (when implemented). The three altitudes operate on disjoint problems: no overlap, no gap.

| Altitude | Stage | Trigger | Mechanism | Forcing function | Status |
|---|---|---|---|---|---|
| **Intake-altitude** (author's-pen) | Stage 1 + Stage 2 A1 DoR | 5-test T1 atomicity fails per [intake-style-guide.md § 2](../../release/references/how-to/intake-style-guide.md) | Author self-applies 5-test; Triage A1 confirms via G1-04 / G1-05 DoR | Self-applied rule + G1 gate | SHIPPED |
| **Triage/Bundle-altitude** (release-altitude) | Stage 2 A5.5 + Stage 3 A1 | G2-11 / G3-12 composite-OR oversize predicate fires (P1 `size:XL` OR P2 declared-decomposition-hook OR P3 AC ≥ 7 OR file ≥ 5) | Triage/Bundle spoke surfaces 3-outcome enum; operator renders kept-as-one / split / escalate | G2-11 / G3-12 gate-blocking (judgment-recommend) | **NEW** |
| **Engineering-altitude** (implementation-altitude) | Stage 6 sub-task scaffolding | Engineering spoke decomposes bundled issue into N sub-tasks per file-touch / capability-axis basis | Hub spawns per-sub-task spokes; sub-tasks live within ONE parent issue + ONE milestone | In-skill structural protocol | SHIPPED |

**Disjoint problem semantics:**

- **Intake altitude:** "Was this ticket atomic when authored?" (1 ticket; pre-Triage)
- **Triage/Bundle altitude:** "Is this Approved/Bundled ticket a single piece of work?" (1 ticket; pre-Engineering)
- **Engineering altitude:** "How do we mechanically chunk implementation of this one ticket?" (1 ticket → N sub-tasks within it; post-bundle)

**Subsumption rule:** G2-11 SUBSUMES G2-10 when its predicate fires (one routing decision under G2-11; G2-10's 4-option enum maps to G2-11's 3-outcome enum: decompose-into-slice → split, split-into-sub-issues → split, approve-as-is-with-risk-note → kept-as-one, defer-for-pre-bundle-analysis → escalate). G3-12 SUBSUMES G3-09 by the same mapping at Bundle. Backwards-compatible — G2-10 / G3-09 stay in spec as the explicit-`size:XL` forcing function; G2-11 / G3-12 stay as the broader-predicate forcing function.

**Retroactive Review Path (per AC #6 — operator-elective):**

The G2-11 / G3-12 gates apply to issues entering Triage / Bundle going forward. For latent-debt protection on the existing backlog, a standing operator-elective retroactive scan path is available:

- **R1 — Operator-elective `--retro-scan` invocation.** Single `gh issue list` query enumerates candidates by `status: approved` / `status: bundled` + body grep for the P2 / P3 predicates. Operator-invoked, not auto-running. NOT a deploy-time check, NOT a `deploy.sh --check` gate.
- **R2 — Per-candidate routing recommendation.** Agent generates a 3-outcome routing recommendation as a `Retroactive Oversize Review` comment template (mirrors the post-cutover Oversize-Review Outcome format); operator renders kept-as-one / split / escalate per the standard 3-outcome enum.
- **R3 — Per-outcome execution.** When operator elects split, the standard fission protocol fires retroactively. When operator elects kept-as-one, rationale recorded on issue. When operator elects escalate, Tier 2 [SCOPE CHANGE] applies per [`release-process.md`](../../release/governance/release-process.md) § Inter-Stage Feedback Protocol.

**Maintenance-affordance note:** R1-R3 is a maintenance affordance, not a re-enforcement. Previously bundled issues remain governed under their original Approval — the protocol does NOT retroactively fail them.

---

## Gate G-BR: Bundle Refresh Readiness

*"Has the bundle drifted enough since creation to require operator decision, and is the refresh decision recorded?"*

**Stage boundary:** Intra-window — fires at refresh-trigger events during Stage 3 Phase B3 → Stage 5 Collective Review approval
**Inherits:** No formal inheritance — composes alongside Gate 3 (the bundle being refreshed must have originally passed Gate 3). Re-validates Gate 3 criteria after amend/re-bundle path.

| ID | Criterion | Type | Check | Automation |
|---|---|---|---|---|
| G-BR1 | Refresh trigger condition valid (T1 ≥3 new Approved theme-matching issues OR T2 priority shift OR T3 dep-state change OR T4 Stage 4 boundary check) | field | structural | auto |
| G-BR2 | Churn magnitude computed (composition_delta_pct + theme_preserved Y/N) | field | structural | auto |
| G-BR3 | Refresh outcome path selected (no-op / amend / re-bundle / defer) with required evidence per [release-process.md](../../release/governance/release-process.md) § A7 — Bundle Mutability Protocol outcome-path table | field | judgment | recommend |
| G-BR4 | Decision recorded on Milestone (description amendment AND/OR `[BUNDLE *]` comment per outcome-path recording mechanism) | artifact | structural | auto |

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G-BR1 | No trigger valid | Path (1) no-op; close refresh check with `[BUNDLE REFRESH: no-op]` comment. |
| G-BR2 | Churn not computed | Re-run computation; missing computation blocks operator decision. |
| G-BR3 | Outcome path selected without required evidence | Return to operator with evidence-gap list; block recording until evidence complete. |
| G-BR4 | Recording absent post-decision | Author the `[BUNDLE *]` comment + Milestone-description update per outcome-path table. Decision is INVALID without recording — Stage 4/5 spokes treat unrecorded refresh as "no decision made" and re-prompt operator. |

---

## Gate 9: Plan Review

*"Is the evidence package complete enough for the operator to render Go/No-Go?"*

**Stage boundary:** 9->12 (Plan Review -> Execute)
**Inherits:** Gate 8->9 + Gate 9->12 from [field-lifecycle-matrix.md](field-lifecycle-matrix.md#gate-8-9-qa---plan-review)

| ID | Criterion | Type | Check | Automation |
|---|---|---|---|---|
| G-PR1 | Evidence package complete (Phase A1-A6 all populated per [pipeline/stage-09-plan-review.md](../../release/references/pipeline/stage-09-plan-review.md) §5 Phase A; Phase A6 = 13-dim Release Readiness Scan per [release-readiness-scan-spec.md](../../release/references/specs/release-readiness-scan-spec.md); the Phase A6 Release Readiness Scan applies to all Stage 9 releases going forward) | artifact | structural | auto |
| G-PR2 | All upstream reports present (Stage 7 quality report + Stage 8 acceptance report + Stage 6 PR + Stage 4 release plan) | artifact | structural | auto |
| G-PR3 | PR scope matches release plan (implementation table conformance to release plan §Implementation Sequence) | validation | structural | auto |
| G-PR4 | Risk register reviewed (all risks mitigated or accepted; status flag set) | field | structural | auto |
| G-PR5 | Deployment readiness checklist all PASS (PR mergeable per `gh pr view --json mergeable`, branch current, metadata complete, rollback available) | validation | structural | auto |
| G-PR6 | Decision record posted (per the decision-record format on gate sub-task + parent issue) | artifact | structural | auto |
| G-PR7 | Release plan implementation conforms to declared Release Outcome Statement per the template. Hub reads the `### Release Outcome Statement` H3 block from the GitHub Milestone description, reads the PR scope (`gh pr view <PR> --json files,additions,deletions`), reads the release plan §Implementation Sequence + File Change Matrix, AND reads each release-scoped issue AC. Renders a 1-paragraph synthesis citing AC-trace evidence: per-issue AC list maps to the AFTER capability; PR scope (file-changes-matrix) implements the AFTER capability; no scope drift since Stage 3. Verdict: **ALIGNED** / **DIVERGED-WITH-RATIONALE** / **MISALIGNED**. LLM-graded recommend check; operator may accept divergence with documented rationale in Decision Record. **Cutover discipline:** The goal-conformance check applies to all Stage 9 releases going forward. | judgment | judgment | recommend |
| G-PR9 | **GO baseline-currency.** The Stage 9 GO records the **baseline SHA** it is rendered against (the release-branch base at GO time, persisted in the release plan's `## Cross-PR Overlap Audit` → `### Baseline SHA` H3), AND the hub evaluates the **sibling-merge revalidation predicate**: `git log <recorded-baseline-SHA>..origin/main --name-status --find-renames`, intersecting the touched / renamed / deleted path-set against this release's structural surface `SURFACE(R)` (the F1 / F2 / F3 / F5 + in-tree-F6 union per the Stage 3 Bundle spec § A9.6.1 structural-blast-radius axis; F4 excluded). The predicate is `--name-status --find-renames` (NOT `--merges`) so it is merge-style-agnostic — the repo lands sibling releases via both merge commits AND squash / fast-forward non-merge commits, and a `--merges`-only filter would return a false CURRENT for a squash landing. Verdict: **CURRENT** (no commit since the recorded baseline intersects `SURFACE(R)`) / **STALE-REVALIDATE** (a sibling merged; revalidation required — re-run the A4 structural sub-audit + Phase A6.5 divergence check against new `main`) / **STALE-VOID** (revalidation surfaces a `SURFACE(R)` intersection → NO-GO, re-baseline). Composes with G-PR8 (Phase A6.5 syntactic File-Change-Matrix-touch check) as a second axis/window — G-PR8 catches a sibling touching this release's *declared* files; G-PR9 catches a sibling whose *mover-set invalidates a path this release's edit-set references* (which need not be in the File Change Matrix) AND records the SHA that makes the GO falsifiable. **Cutover discipline:** applies to releases entering Stage 9 strictly AFTER this criterion's introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline — it cannot fire its own new gate; its Stage 9 runs under the pre-existing G-PR1..G-PR8 checks). | validation | structural | auto |

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G-PR1 | Phase A evidence missing | Return to Phase A; block Phase C decision until evidence assembly complete. |
| G-PR2 | Upstream report missing | Escalate per [release-process.md](../../release/governance/release-process.md) Inter-Stage Feedback Protocol Tier 2 (SCOPE CHANGE) — upstream stage owes return-to-Stage 9. Block decision. |
| G-PR3 | PR scope diverges from release plan | Tier 1 `[ADJUST]` — Engineering amends OR operator approves deviation per release plan Deviation Log. |
| G-PR4 | Risks unaccepted | Return to Stage 4 Planning for risk-mitigation amendment OR explicit "accepted with documented rationale" annotation in Decision Record. |
| G-PR5 | PR not mergeable | Return to Stage 6 Engineering per [release-process.md](../../release/governance/release-process.md) Inter-Stage Feedback Protocol Tier 1/2. |
| G-PR6 | Decision Record missing | Operator posts; Decision Record IS the closure artifact (no separate escalation tier). |
| G-PR7 | Goal-conformance MISALIGNED OR DIVERGED-WITH-RATIONALE | Tier 2 `[SCOPE CHANGE]` per [release-process.md](../../release/governance/release-process.md) § Inter-Stage Feedback Protocol — Outcome was drafted at Stage 3 but scope drifted during execution; operator decides: (a) amend Outcome with documented rationale in Decision Record (DIVERGED-WITH-RATIONALE path), (b) defer specific issues + amend Outcome accordingly, (c) NO-GO and re-bundle (MISALIGNED path). Recommend-tier: operator may also accept ALIGNED-with-divergence finding with documented rationale. |
| G-PR9 | GO baseline SHA unrecorded OR predicate = STALE-REVALIDATE / STALE-VOID | Record the baseline SHA in the release plan `### Baseline SHA` H3 if absent. On STALE-REVALIDATE: re-run the A4 structural sub-audit + Phase A6.5 divergence check against current `main`; if clean, re-render the GO with the new baseline SHA. On STALE-VOID: Tier 2 `[SCOPE CHANGE]` per [release-process.md](../../release/governance/release-process.md) § Inter-Stage Feedback Protocol — re-baseline the release branch on `main` and return to Stage 9 for a fresh GO (fresh-Stage-9-GO-mandatory precedent). |

---

## Gate 12: Execute Readiness

*"Did execution produce a verified, audit-trail-complete deployment?"*

**Stage boundary:** 12->13 (Execute -> Close)
**Inherits:** Gate 12->13 from [field-lifecycle-matrix.md](field-lifecycle-matrix.md#gate-12-13-execute---close)

| ID | Criterion | Type | Check | Automation |
|---|---|---|---|---|
| G-EX1 | PR MERGED (`gh pr view --json state` returns `MERGED`) | artifact | structural | auto |
| G-EX2 | Tag exists on main (`git tag --list <vX.Y>` returns the tag) | artifact | structural | auto |
| G-EX3 | All S-2 deployments completed with zero diff (`core/deploy/deploy.sh --check` exits 0) | validation | structural | auto |
| G-EX4 | Deployment log appended to RELEASE_LOG.md (`grep "vX.Y" <OPERATOR_INSTANCE_RELEASE_LOG_PATH>` returns the entry) | artifact | structural | auto |
| G-EX5 | Release row in RELEASE_LOG.md present (table row + HTML comment block per RELEASE_LOG.md format) | artifact | structural | auto |
| G-EX6 | All Phase C verification PASS (C1-C5 results documented per [pipeline/stage-12-execute.md](../../release/references/pipeline/stage-12-execute.md) §5 Phase C) | validation | structural | auto |
| G-EX7 | No Layer 2 leakage (`git status` clean — no projects/ files committed) | validation | structural | auto |
| G-EX8 | Deferred items documented (release plan Deferred Items section populated) | field | structural | auto |

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G-EX1 | PR not MERGED | Retry `gh pr merge` on transient (HTTP 5xx, lock conflict). Rollback via `git revert` on systemic failure. |
| G-EX2 | Tag missing | Re-tag via signed-annotated form `git tag -a -m "v<X.Y>-<milestone-slug> — <N> issues; release SHA = merge of PR #<n>" vX.Y "$MERGE_SHA" && git push origin vX.Y`. |
| G-EX3 | Diff-non-zero on deployed copy | Re-run `core/deploy/deploy.sh --deploy <skill>` per [skill-deployment.md](../rules/skill-deployment.md) post-merge steps. Rollback via `git revert` on systemic failure. |
| G-EX4 | RELEASE_LOG.md entry absent | Append entry; validate format per RELEASE_LOG.md §"Deployment Log format". |
| G-EX5 | Release row malformed | Re-author row per RELEASE_LOG.md template. |
| G-EX6 | Phase C verification incomplete | Re-run failing verification (C1 merge / C2 deployed-copy / C3 functional / C4 layer-boundary / C5 rollback) per Phase C protocol. |
| G-EX7 | Layer 2 leakage | `git restore --staged projects/*` and `git checkout -- projects/*` to clean working tree. Escalate per Inter-Stage Feedback Protocol Tier 1 `[ADJUST]`. |
| G-EX8 | Deferred items missing | Populate release plan Deferred Items section before Stage 13 entry. |

---

## Gate 13: Close Readiness

*"Is the release fully closed — issues, milestone, log, verification, operational deployment?"*

**Stage boundary:** 13 Exit (Release Close)
**Inherits:** Gate 13 Exit from [field-lifecycle-matrix.md](field-lifecycle-matrix.md#gate-13-exit-release-close)

| ID | Criterion | Type | Check | Automation |
|---|---|---|---|---|
| G-CL1 | All issues CLOSED or documented-deferred (`gh issue list --milestone <X> --state open` returns empty OR all open issues have deferred-rationale documented in release plan) | validation | structural | auto |
| G-CL2 | Milestone CLOSED (`gh api repos/<owner>/<repo>/milestones/<N>` returns `state: closed`) | anchor | structural | auto |
| G-CL3 | RELEASE_LOG.md status VERIFIED (transitioned DEPLOYED → VERIFIED via grep on entry status field) | field | structural | auto |
| G-CL4 | Verification evidence persisted (release plan Verification Evidence section populated with PASS/FAIL per check, post-merge commit) | artifact | structural | auto |
| G-CL5 | Operational deployment manifest fully executed (all Phase B-OPS manifest entries PASS or exception-documented per [pipeline/stage-13-close.md](../../release/references/pipeline/stage-13-close.md) §5 Phase B-OPS) | validation | structural | auto |
| G-CL6 | Design artifacts refreshed when applicability fired during this release. For each Tier-A activated artifact declared in the release plan's "Tier-A activated design artifacts" section, the artifact's last commit SHA is within the release branch commit range AND the diff is non-trivial (>3 line delta, excludes frontmatter-only). Canonical authority: [`design-artifact-standard.md`](../standards/design-artifact-standard.md) § 8. Initial warn-mode posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent; flip-to-enforce at 2-3 release threshold. **Cutover discipline:** The design-artifact refresh-gate applies to all Stage 13 releases going forward. | artifact | structural | auto |
| G-CL7 | Goal-attainment verification recorded per the QC4 protocol. The Stage 13 spoke renders QC4-06 verdict (ATTAINED / PARTIALLY-ATTAINED / NOT-ATTAINED) per Phase A10 of [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) — 1-paragraph attainment narrative citing Change Description (per the template) + Success Indicator (when present) + ≥1 verifiable evidence anchor — appended to release plan Verification Evidence section. The criterion asserts presence of the verdict + narrative, not the verdict value. Initial warn-mode posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent — per-release FAIL logs to `core/hooks/qc4-06-warn-log.jsonl` and Milestone close proceeds; flip to enforce after 2-3 release shakedown. Composes with decision-outcome capture: ATTAINED → SUCCESS / PARTIALLY-ATTAINED → PARTIAL / NOT-ATTAINED → SUCCESS-document-divergence OR ROLLBACK per operator. **Cutover discipline:** Goal-attainment verification applies to all Stage 13 releases going forward. | artifact | structural | auto (warn → enforce) |
| G-CL8 | Documentation Impact resolved for every closed issue in the release per the field spec. For each issue closed by the release PR, the issue body's `Documentation Impact` field is satisfied: declared docs exist and were modified within the release branch's commit range (verified via `git log --follow <docs> origin/main..HEAD`), OR the field reads exactly `None — no documentation impact (rationale: <phrase>)`. The criterion asserts presence + resolution of the declaration; the *absence* of any Documentation Impact value (not the explicit "None — no documentation impact (rationale: ...)" answer) is the gate-failing state. Backed by [`deploy.sh`](../deploy/deploy.sh) Check 28 (`doc-impact-resolution-presence`). **Scope boundary:** K1 codified corpus only — `core/rules/`, `core/`, `core/governance/`, `release/skills/*/SKILL.md` + `references/`, `CLAUDE.md`. Initial warn-mode posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent — per-issue FAIL logs to `core/hooks/doc-impact-warn-log.jsonl` and Milestone close proceeds; flip to enforce after 2-3 release shakedown OR warn-log drained to < 10 entries (whichever first). **Cutover discipline:** The documentation-impact resolution gate applies to all issues entering Stage 1 Intake and all releases entering Stage 13 Close going forward. | artifact | structural | auto (warn → enforce) |

### Self-Repair Actions

| ID | On Failure | Action |
|---|---|---|
| G-CL1 | Issue not auto-closed | Manual close via `gh issue close <N>` when PR `closes #N` keyword failed (e.g., issue moved milestone post-merge). |
| G-CL2 | Milestone open | Re-run G-CL1 prerequisite; close Milestone via `gh api repos/.../milestones/<N> -X PATCH -f state=closed` once G-CL1 PASS. |
| G-CL3 | RELEASE_LOG.md status not VERIFIED | Edit RELEASE_LOG.md to transition DEPLOYED → VERIFIED + commit post-merge. |
| G-CL4 | Verification evidence missing | Back-fill from PR / commit log / `core/deploy/deploy.sh --check` results into release plan Verification Evidence section. |
| G-CL5 | Operational deployment fail | Phase B-OPS rollback per [pipeline/stage-13-close.md](../../release/references/pipeline/stage-13-close.md) Mode 2. Escalate per Inter-Stage Feedback Protocol Tier 2 SCOPE CHANGE if systemic. |
| G-CL6 | Design artifact not refreshed | Identify the artifact; re-run Stage 5 design-artifact production for the affected flow class per [`design-artifact-standard.md`](../standards/design-artifact-standard.md) § 6 + § 7; commit refresh to release branch. If activation was over-declared (artifact does not need refresh), update the release plan to remove the declaration with rationale. Warn-mode posture: log failure to `core/hooks/design-artifact-warn-log.jsonl` and proceed; enforce-mode posture: block Milestone close, operator override per CHEAP reversibility tier (one-line `Override: <rationale>` entry in release plan deviation log). |
| G-CL7 | Goal-attainment verification missing | Stage 13 spoke runs QC4-06 retroactively; appends 1-paragraph verdict + narrative to release plan Verification Evidence section via the Stage 13 chore PR. Warn-mode: log to `core/hooks/qc4-06-warn-log.jsonl` and proceed. Enforce-mode (post-shakedown): block Milestone close, operator override per CHEAP reversibility tier (one-line `Override: <rationale>` entry in release plan deviation log). |
| G-CL8 | Documentation Impact unresolved for ≥1 closed issue | Surface unresolved declarations to operator with diff evidence (per-issue: declared docs vs. `git log --follow` result on the release branch). Operator chooses: (a) extend release with docs commit on release branch via `fix(dt):` or Tier 1 `[ADJUST]` commit, (b) accept deviation with rationale in release plan deviation log, (c) flip declared value to `None — no documentation impact (rationale: <phrase>)` with documented reason. Warn-mode: log to `core/hooks/doc-impact-warn-log.jsonl` and proceed. Enforce-mode (post-shakedown): block Milestone close, operator override per CHEAP reversibility tier (one-line `Override: <rationale>` entry in release plan deviation log). |

---

## Versioning

**Schema version:** 1.11
**Introduced in:** v7.5

**v1.11 changes (non-breaking — minor; additive only):**

- Added G-PR9 (GO baseline-currency) to Gate 9. 1 new structural criterion + 1 self-repair row. The GO records the baseline SHA it was rendered against and the hub evaluates a sibling-merge revalidation predicate (`git log <baseline>..origin/main --name-status --find-renames` intersected against the release's structural-blast-radius surface `SURFACE(R)` per the Stage 3 Bundle spec § A9.6.1 axis); verdict CURRENT / STALE-REVALIDATE / STALE-VOID. Composes with — does not duplicate — the live Phase-A6.5 mid-pipeline-divergence check (a second axis/window; that check is referenced repo-wide as a Gate-9 criterion but is not yet a registered row in this table — its registration is a separate task, not absorbed here, so G-PR9 is added cleanly above that gap). The predicate is `--name-status --find-renames`, NOT `--merges`, because the repo lands sibling releases via both merge and squash / fast-forward non-merge commits.
- Schema bump v1.10 → v1.11 (non-breaking minor; additive only). Schema consumers (automated gate-validation tooling, stage-gate evaluator, CER Claim agents) treat the new criterion as additive. Existing G1-01..G3-13 + G-BR1..G-BR4 + G-PR1..G-PR7 + G-EX1..G-EX8 + G-CL1..G-CL8 IDs unchanged.
- **Cutover discipline (v1.11 additions):** G-PR9 applies to releases entering Stage 9 strictly AFTER its introducing-release merge SHA recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline — it cannot fire its own new gate).

**v1.10 changes (non-breaking — minor; clarification only):**

- Added the **Template-awareness precondition** framing note under § Gate 1 — states the detect-template-before-evaluating rule and its two-directional failure mode (false-positive failures + false-negative passes) that the existing per-template column triple, Template Detection Logic, and Adapter Blocks already implement. No new criterion; no ID added.
- Extended **Adapter G1-06-Bug** with the combined multi-line-aware detector `(Priority|Severity)[\s\n]+P[1-4]` covering both field names in one pattern. Clarifies the existing Severity→Priority semantic mapping; G1-06 behavior unchanged.
- Added the **Body-compliance precondition for the `status: bundled` transition** framing note under § Gate 3 — states the re-run-G1/G3-against-the-body rule, the "labels reflect intent, not body-level compliance" principle, the higher-risk applicability list, the minimum re-check set, and the out-of-scope cases. No new criterion; no ID added.
- Schema bump v1.9 → v1.10 (non-breaking minor; clarification only — no criteria added, no IDs renumbered, no type/check/automation enum changes). Schema consumers (automated gate-validation tooling, stage-gate evaluator, CER Claim agents) require no change.

**v1.9 changes (non-breaking — minor):**

- Retired G3-13 (roadmap-cascade validation) per ADR-012 — initiative-roadmap instances de-scoped to operator-local; the Roadmap-Cascade Validation procedure + detection script are removed, and the G3-13 criterion + self-repair rows are tombstoned in place so cross-references resolve. Non-breaking: the judgment-graded criterion no longer fires (passes trivially) and the G3-13 ID is preserved (no renumbering).
- Schema bump v1.8 → v1.9 (non-breaking minor; retirement only). Existing criterion IDs unchanged.

**v1.8 changes (non-breaking — minor):**

- Added G3-13 (roadmap-cascade validation; judgment-graded recommend). 1 new criterion + 1 new self-repair row + 1 new validation procedure block (Roadmap-Cascade Validation). Per-variant rubric per `altitude:` frontmatter — Program → §3 Now/Next/Later milestone match; Portfolio → §3 Family Member Registry cluster match (per the D-UmbrellaVariant decision). Non-breaking minor; additive only.
- Schema bump v1.7 → v1.8 (non-breaking minor; additive only). Schema consumers (automated gate-validation tooling, stage-gate evaluator, CER Claim agents) treat the new criteria as additive. Existing G1-01..G3-12 + G-BR1..G-BR4 + G-PR1..G-PR7 + G-EX1..G-EX8 + G-CL1..G-CL8 IDs unchanged.
- **Cutover discipline (v1.8 additions):** G3-13 applies to all bundles entering Stage 3 going forward.
- **Audit date:** 2026-06-02 (resolved at Stage 6 first commit via `date -u +%Y-%m-%d` per [`core/standards/date-variable-convention.md`](../standards/date-variable-convention.md)).

**v1.7 changes (non-breaking — minor):**
- Added G2-11 (decomposition-review routing at Triage when ANY oversize predicate matches — P1 `size:XL` OR P2 declared decomposition-hook OR P3 AC ≥ 7 OR file ≥ 5) to Gate 2. 1 new judgment-recommend criterion + 1 self-repair row.
- Added G3-12 (decomposition-review routing at Bundle as drift-backstop for G2-11; same composite-OR predicate) to Gate 3. 1 new judgment-recommend criterion + 1 self-repair row. Mirrors the G2-10 / G3-09 dual-placement precedent (Triage + Bundle drift-backstop).
- Added § Composite-OR Oversize Predicate block under § Gate 2 — referenced from G2-11 + G3-12 criterion bodies. Defines P1 / P2 / P3 with verifiable detection commands.
- Added § Cross-Stage Decomposition Coverage block under § Gate 3 — 3-altitude table (Intake / Triage-Bundle / Engineering) per AC #5; subsumption rule (G2-11 SUBSUMES G2-10 on predicate fire; G3-12 SUBSUMES G3-09 by the same mapping); Retroactive Review Path (R1 / R2 / R3) per AC #6 (operator-elective only).
- Added Cutover discipline for G2-11 / G3-12: applies to all issues entering Triage / Bundle going forward.
- Schema bump v1.6 → v1.7 (non-breaking minor; additive only). Schema consumers (automated gate-validation tooling, stage-gate evaluator, CER Claim agents) treat the new criteria as additive. Existing G1-01..G3-11 + G-BR1..G-BR4 + G-PR1..G-PR7 + G-EX1..G-EX8 + G-CL1..G-CL8 IDs unchanged. SPLIT outcome composes with [fission-convention.md](../../release/references/protocols/fission-convention.md).
- **Note on Stage 5 spec renumbering (Stage 5 sub-task):** Stage 5 spec proposed gate IDs `G2-11` + `G3-10`. `G3-10` was claimed by a sibling (Release Class, commit `adbc8c5`); `G3-11` was claimed by a sibling (Outcome Statement, commit `8dee29f`). `G3-12` is the next-free slot — used here. Tier 1 `[ADJUST]` deviation (informational); no Stage 5 spec-decision change required.

**v1.6 changes (non-breaking — minor):**
- Added G3-11 (Release Outcome Statement heading present in milestone description) to Gate 3. 1 new structural-advisory criterion + 1 self-repair row. Non-blocking advisory at Stage 3 Phase B3.
- Added G-PR7 (Release plan implementation conforms to declared Release Outcome Statement) to Gate 9. 1 new judgment-recommend criterion + 1 self-repair row.
- Added G-CL7 (Goal-attainment verification recorded-06) to Gate 13. 1 new structural criterion + 1 self-repair row. Initial warn-mode posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent; flip-to-enforce at 2-3 release threshold. Composes with `release-outcome-statement-template.md` (canonical authority for the Outcome schema).
- Added G-CL8 (Documentation Impact resolved for every closed issue in the release) to Gate 13. 1 new structural criterion + 1 self-repair row. Backed by [`deploy.sh`](../deploy/deploy.sh) Check 28 (`doc-impact-resolution-presence`). Initial warn-mode posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent; flip-to-enforce at 2-3 release threshold OR warn-log drained to < 10 entries (whichever first). Composes with the new `Documentation Impact` field on `improvement.yml` + `bug.yml` (Stage 1 declaration) and the `### Documentation Impact` H3 subsection on `.github/PULL_REQUEST_TEMPLATE.md` (Stage 6 surface). Scope boundary: K1 codified corpus only.
- Extended G-PR1 wording to reference the 13-dim Release Readiness Scan (Phase A6 of Stage 9 evidence assembly is now the Release Readiness Scan per [`release-readiness-scan-spec.md`](../../release/references/specs/release-readiness-scan-spec.md); the criterion's structural intent is unchanged — Phase A1-A6 populated is still the artifact-presence check). No ID renumber; G-PR1 stable. Composes with `release-readiness-scan-spec.md` (canonical spec for the scan's 13 dims + per-dim evidence schema + 4-value status enum + output template).
- Schema bump v1.5 → v1.6 (non-breaking minor; additive only). Schema consumers (automated gate-validation tooling, stage-gate evaluator, CER Claim agents) treat the new criteria as additive. Existing G1-01..G3-09 + G3-10 + G-BR1..G-BR4 + G-PR1..G-PR6 + G-EX1..G-EX8 + G-CL1..G-CL6 IDs unchanged.
- **Cutover discipline:** Applies to all releases going forward.

**v1.5 changes (non-breaking — minor):**
- Added `improvement | bug | observation` applies-to column triple to every G1 / G2 / G3 criterion table row. Cell values: `req` / `adapt:<adapter-id>` / `n/a` / `conv`.
- Added new structural criterion G1-09 (intake-tier label matches body template) to Gate 1 + G1-09 self-repair row.
- Added Template Detection Logic block (consumed by G1-09 + by all template-aware gates) under § Gate 1.
- Added Gate 1 Adapter Blocks (Adapter G1-01-Bug, G1-01-Obs, G1-02-Bug, G1-05-Bug, G1-06-Bug) under § Gate 1 — inline lexical/semantic translation per Option C (Hybrid) recommendation.
- Added Gate 2 Adapter Blocks (Adapter G2-01-Bug) under § Gate 2.
- Added Gate 3 Adapter Blocks (Adapter G3-05-Bug) under § Gate 3.
- Added Template-Conversion Rule sub-section under § Gate 3 — observation → improvement conversion at Stage 3 Phase A1 (Bundle entry); `BUNDLE-BLOCKED: observation-template requires conversion` failure signal + conversion path + out-of-conversion paths.
- Schema bump v1.4 → v1.5 (non-breaking minor; additive only). Schema consumers (automated gate-validation tooling, stage-gate evaluator, CER Claim agents) treat the column triple as opt-in filter and continue to iterate all rows when no template filter is applied. Existing G1-01..G3-09 + G-BR1..G-BR4 + G-PR1..G-PR6 + G-EX1..G-EX8 + G-CL1..G-CL6 IDs unchanged.
- Origin: 2026-05-11 audit surfaced 3 template-discipline defects: (1) `bug.yml` issues fail G1-06 false-positively because the body uses `Severity` instead of `Priority`; (2) `observation.yml` issues pass gates trivially despite lacking AC / Affected Files / Priority required for Stage 4 Planning; (3) `improvement`-labeled issues with observation-style bodies (or vice versa) bypass both gate paths (retroactively fixed).
- **Cutover discipline:** Applies to all releases going forward.

**v1.4 changes (non-breaking — minor):**
- Added G2-09 (similarity scoring at Triage) and G2-10 (size scoring at Triage) to Gate 2. 2 new judgment criteria + 2 self-repair rows.
- Added G3-08 (in-bundle similarity scoring) and G3-09 (size scoring at Bundle) to Gate 3. 2 new judgment criteria + 2 self-repair rows.
- Added Similarity Composite-Signal Detection block (cluster + edge axis composite signal) referenced from G2-09 + G3-08.
- Added G-CL6 (design-artifact refresh-gate) to Gate 13. 1 new structural criterion + 1 self-repair row. Initial warn-mode posture per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent; flip-to-enforce at 2-3 release threshold. Composes with [`design-artifact-standard.md`](../standards/design-artifact-standard.md) § 8 (canonical authority for the refresh-gate mechanism).
- Added Cutover discipline: the new criteria apply to all issues entering Triage/Bundle/Stage 13 going forward.
- Non-breaking — extends existing Gate 2, Gate 3, and Gate 13 inheritance; existing G1-01..G3-07 + G-CL1..G-CL5 IDs unchanged. Schema consumers (automated gate-validation tooling, stage-gate evaluator) treat new criteria as additive.

**v1.3 changes (non-breaking — minor):**
- Added G3-07 (cross-milestone dependency sequence validation) to Gate 3. 1 new structural criterion + 1 self-repair row + Milestone-Position Resolution algorithm definition. Non-breaking — extends existing Gate 3.
- Added Gate G-BR (Bundle Refresh Readiness, G-BR1..G-BR4). 4 new criteria + 4 self-repair rows. New named gate using stage-abbrev format (consistent with v1.2 G-PR / G-EX / G-CL precedent). Composes alongside Gate 3 at refresh-trigger events.
- Schema consumers (automated gate-validation tooling, stage-gate evaluator) should treat new criteria and new gate as additive.

**v1.2 changes (non-breaking — minor):**
- Added Gate 9 Plan Review (G-PR1..G-PR6), Gate 12 Execute Readiness (G-EX1..G-EX8), Gate 13 Close Readiness (G-CL1..G-CL5). 19 new structural criteria + 19 self-repair rows. Non-breaking — extends existing inheritance pattern; existing G1-01..G3-06 IDs unchanged. Schema consumers (automated gate-validation tooling, stage-gate evaluator) should treat new gates as additive.
- ID format extended to support stage-abbrev variant (G-PR, G-EX, G-CL) alongside the numeric-gate variant (G1-01..G3-06). Discontinuity rationale: Stages 10-11 are compressed (per [release-process.md](../../release/governance/release-process.md) Stage Compression), so a continuous numeric range would imply ranges that don't exist.
- Inheritance Rules table extended with Plan Review, Execute Readiness, and Close Readiness rows.

**v1.1 changes (non-breaking — minor):**
- G1-02 refined from single-tier (Proposal-only) to tier-branched (Proposal + Observation) per . Backwards-compatible: `improvement`-labeled issues evaluate identically to v1.0. Forward-extends: `observation`-labeled issues now have a defined G1-02 branch (previously auto-failed under literal v1.0 reading).
- Self-Repair Actions G1-02 entry split into three branches (improvement / observation / label-missing) matching the criterion branches.

Schema consumers (automated gate-validation tooling, stage-gate evaluator) should reference the schema version to detect breaking changes. Breaking changes (column additions, ID renumbering, type enum changes) increment the major version. Non-breaking changes (new criteria within existing gates, self-repair refinements) increment the minor version.

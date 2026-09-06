<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
# Stage 8: QA Testing

> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
This is the **validate** stage of the pipeline — where the built result is validated against acceptance criteria, after Engineering has built it. Validate release quality from an independent acceptance perspective — the gate that asks "does this meet needs?" (vs. Stage 7's "does this meet specs?"). Produces an acceptance verdict with per-criterion evidence for human review.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | QA testing and acceptance review | Acceptance review against AC, not formal test execution |
| Governance Focus | Test execution, defect management | Acceptance matrix, fitness assessment, escape detection |
| Artifact Inputs | Test plans, test cases, build artifacts | Dev-tested PR, quality report from Stage 7, AC per issue |
| Artifact Outputs | Test results, acceptance sign-off | Acceptance report with per-criterion verdict, fitness assessment |

Key compression: Part 6 Stages 8-9 compressed. No formal test execution environment — acceptance review against AC using LLM-graded evaluation. Relationship to Stage 7: Stage 7 uses QA Auditor in review mode; Stage 8 uses acceptance mode.

## 3. Persona

| Role | Skills-Map Ref | Modes | Autonomy |
|---|---|---|---|
| Decision maker: Human operator | — | — | Tier 3 (renders acceptance verdict) |
| Acceptance reviewer (primary): QA Auditor Skill 11 | Acceptance review | Mode 2 (= SKILL.md Mode H — acceptance review) | Tier 2 (Recommend) |
| Delivery gate (secondary): Delivery Engine | DoD gate | — | Tier 1 (deterministic checks) |

Stage 8 uses acceptance mode (vs. Stage 7 review mode). Principal Engineer lens replaced by Delivery Engine DoD gate lens. Author-reviewer separation maintained (fresh context).

## 4. Inputs
From Dev Testing: quality review report terminating in the structured Handoff Payload per [DT↔QA Handoff Protocol §Forward Handoff](stage-07-dev-testing.md#dtqa-handoff-protocol), iteration history, verdict. On a post-return iteration, DT emits the Verified Signal per the same protocol.
From Engineering: PR with committed changes, sub-task completion, deviation log.
From Planning: verification plan, AC per issue, file change matrix.
From GitHub Issues: AC per issue — primary QA source.
From the runtime-suite contract: [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md) — the domain-keying source that maps a behavioral/runtime AC's deliverable to the runtime suite whose Stage-7 A8 `test-run` outcome (carried in the DT→QA Handoff Payload **Test-results** field) gates that AC at acceptance. Stage 8 reads this map to key which suite-result applies to a given behavioral AC; it does not run the map (execution is Stage 7's A8 concern). See § Phase B → Runtime-Evidence Acceptance below.

Set at Stage 8: per-criterion verdict, acceptance score, Stage 7 escape count, overall verdict (ACCEPT/CONDITIONAL ACCEPT/REJECT/HOLD).

## 5. Process
**Phase A — Entry Validation (Tier 1):** 5 steps — verify Stage 7 verdict (PASS or CONDITIONAL PASS required), PR still mergeable, quality report present with conformant Handoff Payload (per [DT↔QA Handoff Protocol §Forward Handoff](stage-07-dev-testing.md#dtqa-handoff-protocol)), all AC extractable from issues, and PR gate-state clean per the required-gate + mergeability read below. Missing or malformed Handoff Payload → post [ADJUST] signal per the inter-stage feedback protocol Tier 1; DT amends in-place (no full re-review required for format-only corrections).

#### Required-gate + mergeability read (entry-validation input — never an acceptance verdict)

Phase A reads the pull request's own state — `gh pr view <PR> --json
isDraft,mergeable,mergeStateStatus` — and the verdicts of the required
branch-protection checks on the current head. Stage 8 does not re-implement their
detection; it consumes their own results, the same evidence-consumption posture this
stage takes toward the Stage-7 runtime suites. Two predicates, evaluated in this order,
first match wins.

**P1 — Mergeability.** `mergeable` of `CONFLICTING`, or `mergeStateStatus` of `DIRTY`,
is terminal for this block — do not go on to classify checks. A conflicting pull request
has no computable merge ref, so the host dispatches none of the gates triggered on
`pull_request`, and a reading that inspects only conclusions reports the collapsed
rollup green. Mirrors the pre-merge conflict check at
[`stage-12-execute.md`](stage-12-execute.md) Phase A.6.3 rather than authoring a second
conflict predicate.

**P2 — Denominator floor, count stability, then classification.** Read the denominator first: the
branch-protection required-context count for the pull request's own base branch, `gh api
repos/{REPO}/branches/<baseRefName>/protection --jq '.required_status_checks.contexts |
length'`, resolving `<baseRefName>` from the pull request rather than hardcoding the
default branch. Then read every required row with `gh pr checks <PR> --required --json
name,state,bucket,link`;
in this `--json` form the command exits **0** even when a required row is failing or
pending, so branch on the parsed rows and never on the exit code. **The exit code
carries three conditions, not two.** Besides an unresolvable PR and an
authentication failure, `gh` exits **1** with non-JSON stdout — `no required
checks reported on the '<branch>' branch` — when the required roster is
**empty**, which is precisely the zero-row collapse this predicate exists to
detect. Observed on this release's own pull request while its head was
conflicted; the positive control on a healthy pull request returns exit 0 with
the full JSON roster. A non-zero exit must therefore be classified by **reading
stdout**, never assumed to be a failed read. The safety invariant holds either
way — an unparseable read and an empty roster both enter at § 5.1 state 2, same
severity — so the cost is **attribution, not safety**: without this clause the
release is told *the read was unreadable* when the truth is *the population
collapsed*.
**Settle the count before comparing it, and compare it BEFORE classifying.** The required
roster is dispatch-dependent, so poll on `status` — settled means no check reports a status
other than `COMPLETED`, and an incomplete check returns an *empty* conclusion, so a
predicate waiting on `PENDING` / `IN_PROGRESS` / `QUEUED` matches nothing and exits early —
and require the count stable across consecutive polls, against the same head. A count still
rising is unsettled, not a shortfall. Once settled, a row count below the required-context
count fails entry here, terminally, without consulting § 5.1: § 5.1's state 1
`checks-failing` is evaluated first and is *existential*, so a collapsed population holding
one red row would match it and be recorded as merely informational. See
[`stage-07-dev-testing.md`](stage-07-dev-testing.md) § Required-gate + mergeability read for
the full statement of that inversion; Stage 8 mirrors the ordering rather than restating it.
Otherwise classify to exactly one state per the six-state precedence table in
[`release-readiness-scan-spec.md`](../specs/release-readiness-scan-spec.md) § 5.1,
applying its settle allowance and its `isDraft`-only draft predicate; Stage 8 authors no
new state name and no new precedence order.
The `Issue-reference validity gate` is the worked example: the two classes it enforces
are a bare `#N`-form issue reference placed outside a designated reference block with no
inline provenance marker, and a deprecated `IMP-NNN` reference.

**Disposition.** A P1 conflict, a settled row count below the required-context count (the
predicate above, evaluated ahead of § 5.1), or § 5.1 state 2 `checks-unreadable` — a read
that did not complete — **fails Phase A entry validation** and routes per the Inter-Stage
Feedback Protocol. Stage 8 does
not open Phase B against a pull request whose gates did not run. States 1, 3 and 6 do not
fail entry and are recorded in the Acceptance Report as informational findings: a
`bucket` of `fail` on any required row names that gate — and, for the issue-reference
gate, both classes — following the row link for file-and-line detail; a `bucket` of
`pending`, `cancel`, or `skipping`, or a merge-state value § 5.1 does not model, is
recorded as NOT clean rather than passed over.

**The authority here is entry validation, and it is never an acceptance verdict.** This
read produces no MET / NOT MET / PARTIAL, does not key the Step-0 precedence gate, and
does not route a lane — Step 0 keys on per-criterion acceptance verdicts, which this read
does not render, so the Operator Override Record machinery is untouched. What it can do
is refuse entry, as the fifth conjunct of Phase A above. Branch protection on the default
branch remains the authoritative gate for a red required check; this read exists so a red
gate is visible at acceptance rather than first surfacing at the merge attempt, and so a
required population that never reported is distinguishable from one that passed.

**Cutover discipline:** Applies to all releases going forward.

**Phase B — Acceptance Review (Tier 2 Recommend):** 4 steps — extract AC per issue, evaluate each criterion against PR content (LLM-graded), classify findings, render per-issue verdict. Decision card format for each finding:

```
Finding: [ID]
Criterion: [AC item]
Evidence: [what was found]
Verdict: MET / NOT MET / PARTIAL
Severity: [if NOT MET: Blocker / Warning]
```

**Per-criterion verdict enum** (extended for AC drift): `MET / NOT MET / PARTIAL / N/A-WITH-RATIONALE / REINTERPRET-WITH-RATIONALE / FLAG-UPSTREAM` per [`release/governance/release-process.md § Inter-Stage Feedback Protocol § AC-Drift Handling Protocol`](../../governance/release-process.md). Drift verdicts (`N/A-WITH-RATIONALE`, `REINTERPRET-WITH-RATIONALE`, `FLAG-UPSTREAM`) carry a required `Drift-rationale:` field per the protocol; `FLAG-UPSTREAM` routes Tier 1 [ADJUST] or Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol (NOT Lane 2 QA→DT Return per Phase C). **Cutover discipline:** Applies to all releases entering Stage 8 going forward. Each non-MET verdict additionally keys the disposition axis per the **Finding Disposition Decision Framework** below (fix-now / defer / accept), with a strengthened Step 0 gate for `NOT MET` acceptance criteria.

#### Runtime-Evidence Acceptance (behavioral / runtime AC)

Stage 8 does NOT run test suites — execution is Stage 7's concern (Phase A8). This subsection is the acceptance-altitude consumer of that upstream run: for an acceptance criterion that asserts **runtime/behavioral** behavior of a deliverable mapped to a runtime suite per [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md), Stage 8 grades acceptance by **consuming the Stage-7 A8 `test-run` outcome** carried in the DT→QA Handoff Payload **Test-results** field (per [DT↔QA Handoff Protocol §Forward Handoff](stage-07-dev-testing.md#dtqa-handoff-protocol), the `### Output for Stage 8` block).

**Where this sits in the entry flow (read this precisely).** Phase A Entry Validation **validates the Handoff Payload envelope** — it confirms a conformant `### Output for Stage 8` block is present and its required fields (including Test-results) are extractable (line 39). Phase A does NOT grade the runtime evidence; envelope-present is a structural entry gate, not an acceptance judgment. This subsection is the **new Phase B read**: Phase B **reads the Test-results field's Result** for the AC's mapped suite and lets it drive the behavioral AC's verdict. Envelope-validated at Phase A; Test-results-read-and-graded at Phase B — the two are distinct steps, and this rule adds the second.

| A8 Test-results Result (for the AC's mapped suite) | Stage-8 verdict effect on that behavioral AC |
|---|---|
| `PASS` | the runtime predicate is satisfied → the AC may be graded **MET** (the deliverable was exercised and passed); any remaining non-runtime facets of the same AC are still graded by the Phase B LLM-acceptance path |
| `FAIL` | **NOT MET** (Blocker) → the deliverable does not work; routes Lane 2 → QA Return to Dev Testing per Phase C (the FAIL→NOT-MET→Blocker path Gate 8→9's "no unresolved Blocker" already carries — no new gate criterion) |
| `SKIP` (map no-match row 6) OR no mapped suite for this AC's domain | **no runtime evidence available** → the behavioral AC is graded by the existing Phase B LLM-acceptance path against PR content, and the Acceptance Report records `runtime-evidence: none (suite-skip \| unmapped-domain)` so the absence is explicit, not silent |

This is **evidence consumption, not execution** — Stage 8 stays at acceptance altitude ("does the exercised deliverable meet the need?"), reading the run Stage 7 already performed. No suite is re-run at Stage 8. The domain→suite keying is owned by [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md) (single dispatch source of truth, shared with the verification-execution executor); Stage 8 does not fork a second dispatch surface.

**Cutover (introducing-release-exempt).** Applies to releases entering Stage 8 strictly AFTER this rule's introducing-release merge SHA; the introducing release itself is exempt (reflexive-pipeline-loop discipline — a release that ships this rule does not run the rule on its own acceptance, mirroring the Stage-7 A8 introducing-release exemption). A doc/governance/pipeline-internal release additionally has no runtime/behavioral AC to key on, so the rule is vacuously satisfied regardless of the exemption (see § Doc-release no-op below).

##### Worked example — a behavioral acceptance criterion, end-to-end (Stage 7 → Stage 8)

Two co-equal cases are worked below: an **unmapped** domain (web/component — the honest `suite-skip` fallback) and a **mapped** domain (hooks — the runtime evidence actually consumed). The mapped case shows the mechanism WORKING; the unmapped case shows the honest degradation when no suite covers the domain. Both are first-class — the rule is only trustworthy if it grades honestly in the gap AND consumes real evidence where it exists.

**Case A (unmapped domain — honest `suite-skip` fallback).**

**Behavioral AC (verbatim):** "The dismiss control renders on the notification component, and once dismissed the component stays dismissed for the rest of the browser session (dismiss state persists across re-render within the session)."

**Deliverable domain:** `web` / component (a UI component + its session-scoped dismiss-persistence behavior).

*Step 1 — Stage 7 A8 suite selection (execution altitude).* Consult [`runtime-suite-selection-map.md`](../standards/runtime-suite-selection-map.md) §2 with the changed path (e.g. `web/components/Notification.tsx`). Evaluate rows top-to-bottom, most-specific-glob-wins. **No row matches a web/component path** (rows 1–5 target `core/deploy/**`, `core/hooks/**`, `core/deploy/tools/check-doc-links.py`, and the install/onboarding/update entrypoints; there is no web/component row) → the change falls to **row 6 (no match)** → A8 emits `test-run/suite-skip`, a no-op gate. The DT→QA Handoff Payload **Test-results** field carries the single line `NONE — no runtime code path changed`.

> **Honest-gap note:** the absence of a web/component runtime suite is a REAL registry gap in the selection map, surfaced by this example — NOT a defect in this AC. Closing it (adding a `web/**` component-test row that runs the framework's own component test runner under the `/tmp` HOME-override) is out of this card's narrowed scope; it is the map's own extension path. Until then, a web/component behavioral AC has NO runtime-execution evidence at Stage 7, and Stage 8 must grade it honestly rather than fabricate a pass.

*Step 2 — Stage 8 acceptance (acceptance altitude), per Runtime-Evidence Acceptance above.* The behavioral AC maps to `suite-skip` / unmapped-domain → the "no runtime evidence available" row fires. Stage 8:
(i) grades the AC by the existing Phase B LLM-acceptance path against PR content — it inspects the component source + any author-provided evidence (a recorded interaction, a unit/interaction test the author ran, a screenshot or DOM assertion cited in the PR) for the two facets: *renders* and *dismiss-persists-for-session*;
(ii) records in the Acceptance Report: `runtime-evidence: none (unmapped-domain: web/component — no selection-map row)`, so the acceptance verdict is transparent that no automated runtime run backed it;
(iii) renders MET / NOT MET / PARTIAL on the content evidence as usual — a behavioral claim the author could not evidence at all is PARTIAL or NOT MET (the unmet remainder keyed per the Step-0 gate), NOT an automatic MET.

**Case B (mapped domain — runtime evidence consumed).**

**Behavioral AC (verbatim):** "The security hook blocks the disallowed command and exits non-zero; an allowed command passes through and exits zero."

**Deliverable domain:** `hooks` (a `core/hooks/**` security hook + its block/allow runtime behavior).

*Step 1 — Stage 7 A8 suite selection (execution altitude).* Consult the selection map §2 with the changed path (e.g. `core/hooks/block-dangerous-command.sh`). Evaluate rows top-to-bottom → the path matches **row 3** (`core/hooks/**` → hook suite, `bash core/hooks/tests/test-runner.sh`, self (per-runner)). A8 **runs** the hook suite under the `/tmp` HOME-override sandbox and records the outcome. The DT→QA Handoff Payload **Test-results** field carries a real row, e.g. `hook-suite | map row 3 | PASS | 268/0 | sandbox-home-tmp | actions-run:<url> | <ts>`.

*Step 2 — Stage 8 acceptance (acceptance altitude), per Runtime-Evidence Acceptance above.* The behavioral AC maps to a suite whose A8 Result is populated → the `PASS` / `FAIL` row fires (not the no-evidence row). Stage 8:
(i) reads the Test-results Result for the AC's mapped suite (row 3, hook-suite);
(ii) grades the behavioral AC **directly on that result** — `PASS → the AC may be MET` (the deliverable was exercised by the hook suite and passed; the block/allow behavior the AC asserts is exactly what `test-runner.sh` exercises); `FAIL → NOT MET (Blocker) → Lane 2 → QA Return to Dev Testing`;
(iii) records in the Acceptance Report: `runtime-evidence: hook-suite PASS (map row 3, actions-run:<url>)`, so the acceptance verdict cites the run that backed it.

This is the deliverable-exercising acceptance path the runtime-mapped case gets **for free** by consuming the A8 run — no Stage-8 re-execution, one dispatch map, real evidence. Case A degrades honestly where the map has no row; Case B consumes the run where it does. The rule is the same rule in both — only the map lookup differs.

##### Doc-release no-op preservation

Governance/doc/pipeline-internal releases pass Stage 8 unchanged. The Runtime-Evidence Acceptance rule is *conditional on a behavioral/runtime AC that maps to a suite*. A doc/governance/spec release: (1) touches no runtime-mapped path → its Stage-7 A8 already emits `test-run/suite-skip` (row 6); (2) carries no runtime/behavioral AC (its ACs are file-path+state / content predicates) → the rule has **nothing to key on** and does not fire; (3) therefore grades exactly as today via the existing Phase B LLM-acceptance path — **byte-for-byte unchanged verdict**. This is the explicit Stage-8 mirror of the Stage-7 A8 suite-skip no-op row (where Stage 7 says "no path matches → `suite-skip`, no-op gate, no ceremony", Stage 8 says "no runtime evidence / no runtime AC → grade on content as today, record `runtime-evidence: none`"). This card is itself the proof: it is a governance/pipeline-internal deliverable, so its own Stage-8 run takes the no-op path — and, per the cutover exemption above, grades against pre-change Stage-8 semantics regardless.

#### Automated Eval Invocation (Stage-8 registration — EI-S8)

Registered per the
[Automated Eval Invocation Protocol](stage-07-dev-testing.md#automated-eval-invocation-protocol)
(the owning shard — record schema, result→gate projection, FAIL/EXCEPTION escalation
mapping, and the Autonomy Tier 2 — Bounded Auto declaration with its Tier-1 descent
are defined there, consumed here by reference):

| ID | Stage event | Trigger criterion (fires when ALL hold) | Eval surface executed | Executor |
|---|---|---|---|---|
| EI-S8-01 | Phase B (entry-validated) | Phase A entry validation holds — Stage-7 verdict ∈ {PASS, CONDITIONAL PASS}; conformant Handoff Payload; AC extractable | The Stage-8 stage-gate eval set (`stage-08-qa-testing-gate`), executed as written — its `acceptance`-type assertions graded over the release's AC and its structural conformance assertions over the emitted Acceptance Report. Phase B grading is Mode H's §5 constitutive process, which the set's `acceptance`-type assertions exercise — this row registers its automated invocation + record, not new execution semantics | pmo-qa-auditor Mode H — Acceptance Review |

`acceptance`-type results ARE the Phase B per-criterion verdicts (the §5 enum —
NOT MET keys Step-0/Lane 2 exactly as above); report self-conformance FAILs are
fixed before posting or routed [ADJUST]; a run EXCEPTION follows the protocol's
escalation row. Re-entry (Pass M+1 on the Verified Signal) re-fires EI-S8-01 at full
scope per Phase D. No new verdict values, no parallel grading path; operator
engagement only on FAIL/EXCEPTION per the protocol's escalation table.

**Design-Principle Conformance QA dimension** (applies when the release touches the D-Gate-rendering surface or the design-principle register): for each option-level `### Design-Principle Conformance` verdict produced in the release's Decision Briefings / D-Gate renderings, verify the conformance verdict CITES (a) the register entry id (`DP-N`) and (b) the entry's `governing_doc` path:line — a bare `ALIGNED` / `**CONFLICT.**` with no register-entry + `governing_doc` citation is a NOT MET finding (it fails the load-bearing evidence test per `decision-discipline.md` § 5 G1/G3, the same evidence-citation discipline the Upstream-compatibility verdict carries). Cross-check: every `**CONFLICT.**` verdict enumerates ≥1 named mitigation and, when the entry's `conflict_reversibility_default` is EXPENSIVE/IRREVERSIBLE, shows an operator HALT / sign-off (not a silent annotate). This dimension is the acceptance-side twin of `deploy.sh --check` Check 45's deploy-time structural assertion: Check 45 asserts the conformance mechanism EXISTS and the register resolves; this dimension asserts each rendered conformance verdict is EVIDENCE-GROUNDED.

**Phase C — Three-Lane Routing:**

| Lane | Trigger | Action | Return Target |
|---|---|---|---|
| Lane 1: Cosmetic | Minor formatting, non-AC | Note — log, no action required | — |
| Lane 2: AC Gap | AC not met, fixable | Emit QA Return to Dev Testing payload per [DT↔QA Handoff Protocol §Return Path](stage-07-dev-testing.md#dtqa-handoff-protocol) (NOT directly to Engineering) | Stage 7 |
| Lane 3: Acceptance Judgment | Subjective AC, fitness question | Decision card → human review | Stage 9 |

Critical routing difference: Lane 2 returns to Dev Testing, not directly to Engineering. This preserves the quality gate chain and composes with the DT↔Engineering iteration loop as its QA-initiated variant — full specification in the protocol reference.

### Finding Disposition Decision Framework

Phase B renders a **verdict** per criterion (`MET / NOT MET / PARTIAL`) and Phase C routes it to a **lane** (WHERE). This subsection adds the **disposition axis** (WHEN): for each finding, *fix-now* (this release) / *defer* (a future release) / *accept* (as-is). Disposition is rendered by the operator at Phase E (Tier 3); the framework is advisory input, not auto-correction.

**Inherited from the shared framework by reference (NOT re-specified here).** Stage 8 reuses, unchanged, the stage-agnostic disposition machinery defined in [`release/references/standards/finding-disposition-framework.md`](../standards/finding-disposition-framework.md):

- the **5-factor disposition matrix** (§ 3) — Effort (High) · Best-Practice Alignment (High) · Downstream Impact (Medium) · Reversibility/Risk (Medium) · Scope-Window (Low, gate-modifier), each with its Fix-Now / Defer / Accept signals;
- the **Step 1 weighted disposition** logic and the **Step 2 tie-break** order (§ 4) — weight spine High = 3 / Medium = 2 / Low = 1; ties resolve Reversibility-Accept → cheap-and-open-Fix-Now → Defer (the conservative default);
- the **stage-agnostic scoring skeleton** (§ 5) — `disposition(finding) → {fix-now, defer, accept, escalate}`, advisory until calibration justifies promotion.

Stage 8 **defines only its own Step 0 precedence gate** (below) — the stage-specific gate the shared framework's § 6 contract requires each consumer to inject — and **adds** the PARTIAL keying and the three-lane composition. The shared matrix and Steps 1–2 are authoritative in the framework doc; they are **not** duplicated here.

#### Step 0 — QA hard precedence (the strengthened gate)

Stage 8's Step 0 is **strictly stronger** than Stage 7's and is keyed on the per-criterion **verdict** (lines 47/51), not DT severity:

- **NOT MET** → a **contractual gap**. Its **only no-override disposition is fix-now**, routed **Lane 2 → QA Return to Dev Testing** (the existing Phase C path). A NOT-MET AC is **never** Defer or Accept by the weighted layer. **Deferring _or accepting_ a NOT-MET AC requires an explicit operator override with a recorded Operator Override Record** (below). Absent that record, a NOT-MET AC cannot leave the release as anything but fix-now — silent defer/accept is foreclosed. *(This is the override gate; it rides Lane 2.)*
- **PARTIAL** → keyed by its **unmet remainder** (see "PARTIAL deferral criteria" below).
- **MET** → no gate; not a finding requiring disposition.
- **Drift verdicts** (`N/A-WITH-RATIONALE` / `REINTERPRET-WITH-RATIONALE` / `FLAG-UPSTREAM`, line 51) are **out of this gate** — they retain their own `Drift-rationale:` requirement and `FLAG-UPSTREAM` Tier-1/Tier-2 routing per the AC-Drift Handling Protocol. This framework keys only on `MET / NOT MET / PARTIAL`.

**Why stronger than Stage 7:** Stage 7's Step 0 permits an in-scope **Blocker** to be auto-dispositioned **fix-now** by the weighted layer and is silent on override records. Stage 8 (a) keys on the **contractual `NOT MET`** verdict, (b) forbids *any non-fix* disposition of it absent operator sign-off, and (c) requires that sign-off to be **recorded** — because an acceptance criterion is a commitment from issue creation, and deferring/accepting it is a conscious scope change, not routine prioritization.

**Operator Override Record — trigger.** *Single normative statement. Every other mention of this obligation — elsewhere in this file, in other stage specs, in skills, and in templates — **cites** this statement rather than restating it, per [`duplicate-source-discipline.md`](../../../core/standards/duplicate-source-discipline.md) §1 condition 2 (consolidate to one canonical source with cross-references).*

A record is required when, and only when, a criterion is dispositioned **`Defer`** or **`Accept`** AND either:

1. its Phase B verdict is **`NOT MET`**; or
2. its Phase B verdict is **`PARTIAL`** and its unmet remainder is **AC-blocking** — classified by the Test in § PARTIAL deferral criteria below.

**Explicitly: a `PARTIAL` whose unmet remainder is non-AC-blocking requires NO record** — it is dispositioned by the Step 1 weighted layer per § PARTIAL deferral criteria. A **`fix-now`** disposition requires no record at any verdict, and the drift verdicts are out of this gate (see the Step 0 bullets above).

Record fields:

| Field | Content |
|---|---|
| **Criterion** | the AC item verbatim (the contractual text being dispositioned away from fix-now) |
| **Verdict + evidence** | `NOT MET` / `PARTIAL` + the Phase B evidence line (what was found) |
| **Disposition** | `Defer` or `Accept` (the non-fix disposition being authorized) |
| **Operator rationale** | why the conscious scope change is acceptable (1–3 sentences; "routine prioritization" is **not** a valid rationale) |
| **Reversibility + landing** | reversibility tier + where the gap lands: **Defer** → a next-release issue number (the gap gets a tracked home); **Accept** → recorded in the Acceptance Report fitness assessment |

The agent **surfaces** the gap and the *requirement* for an Override Record wherever the trigger above fires; it does **not** self-author the override (Tier 3 — acceptance is human judgment per § 8). **CONDITIONAL ACCEPT** is the **named vehicle** for an accepted criterion the trigger reaches: at Phase E such a verdict **must** carry one Override Record per **triggering** criterion — this is the existing "documented rationale" of that verdict made specific. Whether a given criterion triggers is decided by the trigger above and is not restated here; no parallel verdict is invented.

#### PARTIAL deferral criteria

A `PARTIAL` keys the gate by its **unmet remainder**:

- **Unmet remainder is non-AC-blocking** (cosmetic, outside the AC's contractual scope, or aspirational with no documented commitment) → routes the **Step 1 weighted layer**: a deferral opens a next-release issue; an acceptance carries the one-line weighted-layer rationale. The § Step 0 trigger does **not** fire, so no Override Record attaches. This is the "substantially met, minor remainder" case CONDITIONAL ACCEPT contemplates.
- **Unmet remainder is itself an acceptance commitment** (a contractual sub-criterion is undelivered) → **escalates to the Step-0 NOT-MET gate**: fix-now (Lane 2 → DT return) is the only no-override disposition; defer/accept fires the § Step 0 trigger and requires the Operator Override Record.
- **Test:** *"Is the unmet portion something we agreed to deliver?"* — **yes → NOT-MET gate**; **no → weighted layer.**

**Worked example — both arms.**

- **Non-AC-blocking remainder → no record.** A criterion reads *"the reconciled rule carries a worked example."* At acceptance the example is present and matches the rule, but sits one subsection above where the author intended. Verdict `PARTIAL`. Test — *is the unmet portion something we agreed to deliver?* **No**: the criterion committed to the example existing and matching, not to its placement. Remainder is **non-AC-blocking** → Step 1 weighted layer → `accept` with the one-line weighted rationale, recorded in the fitness assessment. **No Operator Override Record.**
- **AC-blocking remainder → record required.** A criterion reads *"the rule states explicitly whether the non-triggering case requires a record."* At acceptance the rule states the triggering case and leaves the non-triggering case to inference. Verdict `PARTIAL`. Test: **Yes** — naming that case *is* the criterion's contractual content, and it is undelivered. Remainder is **AC-blocking** → escalates to the Step-0 gate → `fix-now` is the only no-override disposition; `defer` or `accept` **requires the Operator Override Record** per the § Step 0 trigger.

The pair is this gate's falsification arm: the first case shows the trigger **declining to fire**, the second shows it **firing**. A trigger that only ever fires is not a trigger.

#### Disposition × three-lane composition

The lane says WHERE a finding routes; the disposition says WHEN it is addressed; Step 0 constrains WHICH dispositions are legal for a NOT-MET/PARTIAL AC.

| Lane (Phase C) | Disposition composition |
|---|---|
| **Lane 1 — Cosmetic** (non-AC) | **Accept (informational)** by default — the existing "Note — log, no action required" *is* the accept disposition; the weighted layer is not exercised and Step 0 does not fire (no AC at stake). |
| **Lane 2 — AC Gap** (`NOT MET`, fixable) | **Step 0 fires.** Default = **fix-now** → the existing QA Return to Dev Testing path. **Defer or Accept is legal only with the Operator Override Record.** The override gate lives here. |
| **Lane 3 — Acceptance Judgment** (subjective AC, fitness) | **Tier-3 disposition by the operator at Phase E.** A subjective/fitness AC judged acceptable-as-is is an **Accept**; it carries the Override Record exactly when the § Step 0 trigger fires for that criterion. The weighted layer is advisory input to the judgment. |

#### Stage 7 ↔ Stage 8 differentiation (what is shared vs. what QA overrides)

This is the inverse view of the differentiation note in [`stage-07-dev-testing.md`](stage-07-dev-testing.md) § Finding Disposition Decision Framework: Stage 7 states "what QA will override"; this states "what QA inherits + its stronger gate."

| Element | Stage 7 (Dev Testing) | Stage 8 (QA — this stage) |
|---|---|---|
| 5-factor matrix (§ 3) | references the shared framework | **inherited unchanged** (references the same shared framework) |
| Step 1 weighted disposition + Step 2 tie-break (§ 4) | references the shared framework | **inherited unchanged** (references the same shared framework) |
| Step 0 hard precedence | open **Blocker** → fix-now-or-escalate; never silent defer/accept; **Note** → Accept | **STRENGTHENED:** **NOT-MET AC** → fix-now is the only no-override disposition; defer/accept needs a **recorded operator override**. Strictly stronger — Stage 7 permits in-scope Blocker auto-fix-now and records no override; Stage 8 forbids any non-fix disposition of a NOT-MET AC absent recorded sign-off. |
| Finding vocabulary | DT severity (Blocker / Warning / Note) | QA per-criterion verdict (`MET / NOT MET / PARTIAL`); NOT-MET keys the gate, PARTIAL keys by unmet remainder; drift verdicts are out-of-gate |
| Routing on Defer | new next-release issue | **same**, plus a deferred criterion that the § Step 0 trigger reaches additionally requires the Operator Override Record |

**Phase D — Iteration Loop:**
QA Pass 1 → Route findings per lanes → Lane actions executed (Lane 2 triggers QA→DT Return per [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol); DT runs full re-review per the DT-Eng iteration loop, iterates with Engineering, emits Verified Signal on PASS) → QA Pass 2 (full re-review per Stage 8 §5 Phase D) triggered by Verified Signal → If new findings, route again → Escalation at iteration count > 2 (flag to operator). Iteration cap rationale: more than 2 passes indicates a systemic issue, not incremental fixes.

**PR review-comment → edit → resolving-reply path (Phase D; autonomy-tier-bound).** When a QA-surface finding arrives as a **GitHub PR review comment / review thread** on the release PR (as opposed to an internal QA finding card), it is handled by the same machinery — the channel is an alternate arrival surface, tiered by change-nature — within the trusted set per the author-association trust boundary there — per [`release-process.md` § Inter-Stage Feedback Protocol → PR review comments as a feedback surface](../../governance/release-process.md#inter-stage-feedback-protocol):
- **Tier 1 [ADJUST]** (minor QA correction, no AC/scope/sequence touched): the fix routes via the existing `fix(qa):` commit convention on the release branch (the QA-surface analogue of the `fix(dt):`/Lane-2 machinery); the spoke posts a **resolving reply** on the originating PR review thread when the fix lands, closing the loop on that comment.
- **Tier 2 [SCOPE CHANGE] / Tier 3 [PLAN REJECTION]** (the comment requires scope/sequence/AC change, or rejects the plan): routed to the operator per § Inter-Stage Feedback Protocol — the QA spoke does not silently absorb a scope-affecting comment as a Tier 1 edit.
- An **AC-gap** comment (AC not met, fixable) rides the existing **Lane 2 → QA Return to Dev Testing** path per Phase C (not directly to Engineering — preserving the layered review chain); the resolving reply is posted when the returned fix re-passes QA.

The tier binding is by the *nature* of the requested change, never by the fact that it arrived as a comment. **Single-operator posture:** under the single-operator reviewer convention the PR ships with no assigned external reviewer, so no *trusted-reviewer* comments arrive in steady state and this path is exercised rarely — rarely, not never: on a public repository unsolicited third-party comments can arrive at any time. The author-association trust boundary (per the protocol reference above) gates entry to the tier-mapping — a comment outside the trusted set is surfaced to the operator as untrusted third-party content and is never absorbed as a QA finding, requirement, or instruction. **Cutover discipline:** Applies to all releases entering Stage 8 going forward.

**Phase E — Human Review (Tier 3):** 3 verdicts — ACCEPT (all AC met, fitness confirmed), CONDITIONAL ACCEPT (minor gaps with documented rationale), REJECT (AC gaps requiring Engineering rework) / HOLD (scope question requiring Planning review). For each finding, apply the **Finding Disposition Decision Framework** to render disposition (fix-now / defer / accept); a CONDITIONAL ACCEPT covering any criterion the framework's § Step 0 trigger reaches MUST carry an Operator Override Record per that trigger.

##### Phase E3 — REJECT/HOLD upstream re-scope routing (requirements-clarity vs implementation)

A Phase E REJECT/HOLD splits on whether the gap is an **implementation defect** or a **requirements-clarity / premise problem** — the two route to different upstream stages:

- **Implementation REJECT** (the AC is sound; the build does not meet it) → **Engineering rework** via the existing Lane 2 → QA Return to Dev Testing path (§ Phase C). Release-state: HOLD until the rework lands and re-review passes.
- **Requirements-clarity REJECT / HOLD** (the AC itself is stale, ambiguous, subsumed, or premise-invalid — the scope question Phase E names as HOLD) → the **Tier 0 — Premise Rejection** protocol, NOT Engineering. Per [`release/governance/release-process.md` § Inter-Stage Feedback Protocol → Tier 0 — Premise Rejection](../../governance/release-process.md), the operator chooses among **(A) Return to Triage**, **(B) Override + proceed with deviation log**, or **(C) Defer to next release**; the underlying finding is the **C3 (should-be-challenged)** classification per [`triage-design-rereview.md`](../standards/triage-design-rereview.md) § 3. **Artifact on REJECT:** the spoke posts the **Tier 0 escalation block** ([`triage-design-rereview.md`](../standards/triage-design-rereview.md) § 9 template) on the **parent issue** (not the sub-task) and HOLDS the sub-task open; **re-entry** is Triage re-running with the re-review evidence as input (it may re-bundle into the same Milestone or be excluded), which re-enters this pipeline at Stage 4. This is the WHEN/WHO routing for a premise-level REJECT, distinct from the Finding Disposition Decision Framework above (which keys the fix-now/defer/accept disposition of an in-scope NOT-MET AC).

**Release-state on either REJECT = HOLD until resolved.** This subsection **cites** the Tier-0 protocol and the disposition framework; it does not restate them (duplicate-source-discipline) — the authoritative routing options, escalation-block template, and re-entry mechanics live in `release-process.md` § Inter-Stage Feedback Protocol and `triage-design-rereview.md` §§ 3/9.

**Ticket lifecycle:** Claim: set Stage→8-QATesting. Execute: A-E. Resolve: post acceptance report, route per verdict. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).

**Framework dimensions touched:** Handoff (QA return to DT protocol); Tracking (acceptance sign-off). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Acceptance Report: acceptance matrix (per-criterion verdict), acceptance score, fitness assessment, Stage 7 escape log, lane distribution, overall verdict. Downstream: to Stage 9 (acceptance report + PR + DT report) or to Stage 7 (Lane 2 findings emitted as QA Return to Dev Testing payload per [DT↔QA Handoff Protocol §Return Path](stage-07-dev-testing.md#dtqa-handoff-protocol)).

The Acceptance Report is rendered from the canonical template at [`operations/templates/qa-acceptance-report-template.md`](../../../operations/templates/qa-acceptance-report-template.md) — three reader tiers (verdict / detail / evidence) carrying these six sections, with a machine-parseable acceptance-matrix block whose columns and all-drift-out score are the co-design contract with the `acceptance` assertion type ([`core/skills/eval-writer/references/acceptance-assertion-type.md`](../../../core/skills/eval-writer/references/acceptance-assertion-type.md)).

Stage 8 does NOT produce: quality scores (Stage 7), design decisions (Stage 5), deployment actions (Stage 12).

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
Metrics: all AC checked, acceptance matrix complete, no unresolved Blocker findings, escape detection performed, iteration count logged, report posted; incoming deferred items accounted (every item whose Target stage = this stage, per [deferred-item-tracking.md §13](../standards/deferred-item-tracking.md), is picked up or re-deferred with rationale — zero unaccounted incoming deferrals); registered eval invocations executed (or SKIP no-op recorded) per [Automated Eval Invocation Protocol](stage-07-dev-testing.md#automated-eval-invocation-protocol).
Judgment (1-5): AC coverage thoroughness, evidence quality, fitness assessment, escape detection, report clarity.
Calibration: ambiguous AC rate, QA escapes to Stage 9, iteration count. Threshold adjustment after 3+ releases.

## 8. Automation Level
Overall Tier 2 (Recommend). More human-dependent than Stage 7 — acceptance is inherently human judgment. Agent evaluates and recommends; operator decides. Tier 1 only for deterministic entry checks and report assembly.

## 9. Gap Summary
6 gaps. The Stage 7→8 handoff format and QA→DT return path resolved via [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol).

## 10. Retro
To be populated after execution. Incorporates patterns from the three-lane routing, iteration loop, decision-weighting, user engagement, and full re-review scope decisions.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `qa-acceptance` / `qa-rejection` | QA verdict rendered at Phase B; ALSO captured in `calibration-data.md` — payload carries `projects_to: calibration-data.md:<row-anchor>` | `spoke:#N` (QA spoke) |
| `iteration` | `qa-dt-pass-N` | QA↔DT Lane 2 return per [DT↔QA Handoff Protocol](stage-07-dev-testing.md#dtqa-handoff-protocol); ALSO captured in `iteration-log.md` — payload carries `projects_to: iteration-log.md:<row-anchor>` | `hub` |

Cutover discipline: applies to all releases going forward.

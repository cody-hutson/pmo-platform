---
title: Agent-to-Script Promotion Framework
purpose: Governs promotion of repeated agent-executed mechanical work into governed scripts — the AS0–AS4 promotion ladder, promotion triggers, authoring/review path, testing standards, drift monitoring, agent-script interface (discovery + invoke-vs-re-derive), and versioning/deprecation — across the platform script estate (core hooks/deploy, release tools, skill-bundled scripts).
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: governance
framework_version_anchor: "v1.09"
consumers: "future Stage 5 Solutioning spokes (promotion decisions cite the trigger table); release pipeline Stage 2/3 (candidate intake per the readiness enum); deploy.sh Check 18 (catalog row); script authors (placement + testing tables); skill authors (agent-script interface §5)"
---

# Agent-to-Script Promotion Framework

The platform's long-term autonomy goal — log issue → wake up to a digestible brief → approve → automated deploy — depends on high-confidence deterministic paths for mechanical work, so agent tokens concentrate on judgment. Before this framework, each scripting decision was ad-hoc: the estate grew at least five distinct governance patterns with no rule for when a repeated pattern earns scripting, where the script lives, how it is tested, or how agents find it. This framework makes each scripting decision **citable instead of ad-hoc**.

It composes with three existing surfaces and deliberately duplicates none of them:

- `core/schemas/gate-criteria-spec.md` Check enum (structural / metrics / judgment) — the **work-class axis**: what kind of check a step is. This ladder encodes the orthogonal **implementation-form axis**: what form the step's executable takes. A structural check legitimately lives at any rung.
- `core/specs/autonomy-tiers.md` — WHO acts under what authorization, and the prefixed-tier discipline (its disambiguation table manages four numbered tier conventions and forbids bare-tier citations — the reason this ladder's rungs carry the `AS` prefix rather than becoming a fifth bare "Tier N").
- `release/governance/release-process.md` § Stage Compression — the founding precedent: stages compress where "git mechanisms provide their function automatically." Deterministic tooling replaces agent process; this framework generalizes that principle's decision criteria.

## The promotion ladder (AS0–AS4)

Decision record: `core/ADRs/ADR-020-agent-script-promotion-ladder.md` (Accepted). Each rung names an implementation **form**; every member of the live estate classifies into exactly one rung.

| Rung | Name | Form | Live members (evidence at the v1.09 audit SHA) | Invocation path |
|---|---|---|---|---|
| **AS0** | Agent procedure | Prose rule / SKILL.md step; agent re-derives each run | Most skill mode steps; triage Phase A judgment steps. 17 of the 22 deployed skills cite zero scripts (deployed-roster population) | Agent in-context |
| **AS1** | Documented command | Canonical copy-run command block embedded in the governing doc | Composite-OR predicate detection blocks (`core/schemas/gate-criteria-spec.md`); parser-clean pre-submit grep (`core/rules/git-workflow.md`); Pattern-C manual-checklist grep (`core/rules/doc-link-maintenance.md`); native-dep mirror pseudocode (the Stage 2 triage shard) | Agent copies verbatim |
| **AS2** | Tracked tool (agent-invoked) | Standalone in-tree script; allowlisted when a bash CLI; cited at point-of-use | `release/tools/blast-radius.sh`; `release/tools/append-pipeline-event.sh`; `pmo-skill-refiner`'s 11 bundled `scripts/`; `install.sh` / `update.sh` entrypoints | Agent invokes at the cited step |
| **AS3** | Checkpoint-wired | Script invoked by another governed executable; runs as part of the checkpoint, not at agent discretion | `deploy.sh --check` primitives (`check-doc-links.py`, `check-version-anchors.py`, `lint_release_corpus.py`); install/update phase scripts (`orchestrate.sh`, `compose.py`, `setup-workspace.sh`); `automated-closeout.sh`'s callee tools (`cleanup-orphan-state.sh`, `compute-cycle-time.sh`, `synthesize-release-learnings.sh`) | Checkpoint invocation |
| **AS4** | Autonomous guard | Runs with zero per-use invocation — event-triggered enforcement | PreToolUse hooks (`core/hooks/block-*.sh`: rule IDs + allowlists + warn→enforce); CI workflow gates and their scripts (`check-release-links.py`, `check-skill-licenses.py`); `git-pre-commit-pii.sh` | Event-triggered |

**AS2/AS3 boundary — caller-type test (deterministic):** a script is **AS3 iff its invoker is another governed executable** (a `deploy.sh --check` case-arm, an `install.sh`/`update.sh` phase, a suite runner, a parent orchestration script); it is **AS2 iff an agent invokes it directly** at a cited step. A script serving a checkpoint but invoked by an agent is AS2 (the Stage 13 close-out orchestrator is the canonical example: it serves a checkpoint, an agent runs it — AS2 — while the four tools *it* invokes are AS3). At AS3/AS4, audits derive `invocation_path` from the **caller registration** (the caller script's invocation line, hook wiring, or workflow YAML) rather than from citation topology — a doc can cite a script it no longer invokes; a caller's case-arm cannot. Doc citations remain the discovery layer (§5).

**Mixed-determinism rule (the ladder's central adjudication):** a step whose Check class per `core/schemas/gate-criteria-spec.md` is *judgment* never promotes end-to-end past AS1 — only its **evidence-gathering substrate** promotes (split promotion: script gathers, agent judges). Structural and metrics steps may promote fully to AS2–AS4. Scripting a judgment step end-to-end is the judgment-laundering failure mode below.

**Promotion lifecycle** (process-flow, Tier-A artifact):

```
pattern observed (audit row, repeated session work, or intake item)
        │
        ▼
§1 trigger evaluation ──── GATE: ≥1 trigger fires AND no counter-signal ──── no → stay at current rung; WATCH
        │ yes
        ▼
target-rung selection (ladder + split-promotion rule for judgment-class steps)
        │
        ▼
§2 authoring + review (release PR; promotion decision line in PR;
   discovery anchor lands in the SAME PR; bash CLIs ship their
   allowlist entries; hooks add warn→enforce shakedown)
        │
        ▼
§3 tests per target rung
        │
        ▼
registration (discovery anchor cited at point-of-use; catalog row
   when the artifact is a framework-class doc)
        │
        ▼
§4 drift monitoring (per-rung signals; audit re-run trigger)
        │
        ▼
§6 versioning / deprecation (demotion is a governed change)
```

## §1 Promotion Triggers

A pattern earns promotion when **≥1 trigger fires AND no counter-signal holds**. Each promotion records a **promotion decision line** in the authoring PR: trigger(s) fired + counter-signals checked + target rung + discovery-anchor location (the line Stage 9 review verifies — §2).

| Trigger | Definition | Evidence form |
|---|---|---|
| **T-REP** | Repetition ≥2 across distinct sessions or releases — the platform's N=2 emergence convention. The upstream skill-creator encodes the same signal for skill-bundled scripts: repeated helper work across runs → put it in `scripts/` and tell the skill to use it | `[SOURCE]` occurrence citations (≥2) |
| **T-VAR** | Output variance on identical input — the agent re-derives the step differently across runs | Two differing run outputs, cited |
| **T-DET** | The step is structural or metrics class per the gate-criteria Check enum — precondition for full AS2+ promotion (judgment steps split-promote only) | The gate row's Check-class cell |
| **T-RISK** | Misexecution cost is behavioral/structural-tier blast radius (a wrong run corrupts governed state or silently disables a control) | Named failure scenario |
| **T-TOK** | Mechanical token spend disproportionate to judgment content — the agent burns context re-deriving what a script would do deterministically | Step-size observation |

**Counter-signals (do-NOT-promote, any one blocks):**

| Counter-signal | Rationale |
|---|---|
| Pattern changed within the last 2 releases | The script would ossify the wrong shape (premature-promotion failure mode) |
| <2 `[SOURCE]` occurrences | Below the emergence bar; WATCH-class only |
| Judgment-majority step | Split-promote the substrate at most; never the judgment (mixed-determinism rule) |
| Upstream surface in flux | The promoted form would chase a moving target; wait for upstream stability |
| An existing guard already owns the failure mode at a higher rung | Redundant promotion: a one-line AS1 block backstopped by an AS4 CI gate gains nothing from an AS2 middle layer |

## §2 Authoring & Review Path

Placement by invocation surface (where the script lives is a function of who invokes it):

| Invocation surface | Placement | Live precedent |
|---|---|---|
| Runtime guard (PreToolUse / git hook) | `core/hooks/` | the `block-*.sh` family |
| Deploy / install checkpoint primitive | `core/deploy/` or `core/deploy/tools/` | `check-doc-links.py`, `check-version-anchors.py` |
| Pipeline-stage tooling | `release/tools/` | `blast-radius.sh`, `automated-closeout.sh` |
| Skill-bundled executable | `<module>/skills/<skill>/scripts/` (upstream `scripts/` convention) | `pmo-skill-refiner/scripts/` |
| Install / onboarding verification | `docs/scripts/` | `setup-workspace.sh`, `validate-install.sh` |

Review and registration requirements (all REQUIRED unless marked):

| Requirement | Rule |
|---|---|
| Review path | Standard release pipeline — the promoting change rides a release PR; Stage 9 review is the human gate |
| **Promotion decision line** | The PR records trigger(s) fired + counter-signals checked + target rung + discovery-anchor location (§1) |
| **Discovery anchor lands in the promoting PR** | The point-of-use citation (§5) is part of the promotion itself, not a follow-up — Stage 9 review verifies it via the promotion decision line. A promotion without its anchor is incomplete (shelfware failure mode) |
| Allowlist entry (bash CLIs) | New bash CLIs ship their script-execution-allowlist entries in the same release — the runtime guard layer blocks unallowlisted subprocess script execution **wherever that guard is in force** (see the four-condition coverage boundary in §5) |
| **The obligation fires on agent-execution, not only on addition** | The row above is necessary and not sufficient. A script already in the tree that **becomes agent-executed** — a stage spec starts mandating it, a hub or spoke procedure starts invoking it, a checkpoint starts chaining it — incurs the identical allowlist obligation at that moment, and it is the moment most often missed because no new file appears in the diff. The failure is silent from the author's side and total from the agent's: the spec mandates a command the agent cannot run. Treat "this step now runs a script" as the trigger, not "this PR adds a script" |
| Shakedown (hooks only) | New AS4 hooks follow the warn→enforce shakedown discipline in `core/rules/bypass-mode-readiness.md` before enforcing |
| Language defaults (RECOMMENDED) | bash for git/CLI orchestration, python3 stdlib-only for parsing/validation — the estate precedent at the v1.09 audit: 47 sh / 24 py of 71 tracked scripts |
| Self-description header (RECOMMENDED) | Purpose / invocation / consumers comment block — hygiene, not the discovery mechanism (§5) |

## §3 Testing Standards

Per-rung requirements; the estate's observed gradient (audit §4 finding: governance pattern correlates with rung) codified:

| Rung | Test requirement | Live precedent |
|---|---|---|
| AS0 / AS1 | None — doc-reviewed at PR time like any governed prose | command blocks reviewed in their governing docs |
| AS2 | Self-test flag (`--self-test`) or companion test file RECOMMENDED; **REQUIRED when the output is schema-consumed** by a downstream surface | 11 of the estate's tracked CLIs carry a literal `--self-test`; `bundle-issues-parser.py` carries both self-test and a companion test |
| AS3 | Test REQUIRED — checkpoint correctness is load-bearing (a broken checkpoint primitive silently breaks every release that runs it) | `core/deploy/tests/` 8-test family over the install/deploy phases |
| AS4 | Test suite REQUIRED + warn-mode shakedown before enforce — a faulty guard blocks legitimate work platform-wide | `core/hooks/tests/*.test.sh` + `test-runner.sh`; warn→enforce per the hook-layer reference |

## §4 Drift Monitoring

A promoted script can diverge from the pattern it embodies. Per-rung drift signal + responsibility:

| Rung | Drift signal | Detection responsibility |
|---|---|---|
| AS1 | Command block no longer matches current state (paths moved, flags renamed) | The consuming spoke flags at use — a failing copy-run block is itself the signal |
| AS2 | Citation rot (doc-link Pattern A on the anchor) + pattern evolution | Doc-link maintenance checks catch dead anchors; the audit re-run re-codes `current_rung` and anchor state |
| AS3 | Checkpoint warn-log accumulation; checkpoint output diverging from its consuming check's expectation | Warn-log review at the deploy-check cadence |
| AS4 | Allowlist-addition rate + false-positive rate during and after shakedown | Shakedown reviews per the hook-layer reference; allowlist-additions log |

**Audit re-run trigger:** ≥5 new tracked scripts since the last script-promotion audit OR a module restructure. Instrument: the script-promotion-audit container pattern (dated operator-instance analysis folder; census + segmentation + ranked inventory — the same 9-step methodology the v1.09 audit executed). The audit re-codes every row's rung and anchor state, which is what catches silent demotions and shelfware accumulation.

## §5 Agent-Script Interface

**Discovery-anchor rule:** every AS2+ script names **≥1 discovery anchor** — a point-of-use citation in the governing doc that owns the workflow step (pipeline shard, rules file, standard, spec, or SKILL.md body). The agent's existing read path IS the discovery mechanism: agents read governing docs at the point of work, so a script cited at its step is found exactly when needed. Anchor-less scripts are audit-coded shelfware signals. At AS3/AS4 the **caller registration** (checkpoint case-arm, hook wiring, workflow YAML) additionally serves as ground-truth discovery for audits — doc anchors remain the agent-facing layer, caller registration the machine-facing one.

**Invoke-vs-re-derive rule:** when a governed AS2+ script exists for a step, agents **invoke it**; re-derivation is deprecated. This generalizes the shipped precedent — once the blast-radius tracer existed, the Stage 5 shard deprecated manual grep for that step. Documented opt-out: when the script's applicability predicate fails for the case at hand (the domain-mismatch pattern), the agent states the mismatch and proceeds manually — an explicit, citable exception, not silent divergence.

**Skill-bundled scripts:** skills bundle executables in `scripts/` and cite them in the SKILL.md body — the upstream skill-creator's own documented practice ("write it once, put it in `scripts/`, and tell the skill to use it"), recorded as `aligned` in `core/standards/upstream-reference-catalog.md`. **No new SKILL.md frontmatter field** is introduced by this framework: the v1.09 design evaluated a `scripts:` frontmatter route and a standalone registry spec, and rejected both — frontmatter touches the roster-wide skill-authoring surface for an outcome the body-citation convention already achieves, and a registry without an enforcement check would drift silently (see §6 growth path). The convention binds **scripts** (each AS2+ script must be cited somewhere governing), not skills — a skill that consumes no scripts changes nothing.

**Allowlist requirement (restated from §2):** within the guard's coverage an agent can only invoke what the runtime guard layer permits — bash CLIs require their script-execution-allowlist entries, so a promotion that skips the allowlist ships a tool agents cannot run in a covered session. The obligation is triggered by a script becoming **agent-executed**, not only by a script being **added**: a tool that has sat in the tree for releases incurs it the moment a spec, procedure or checkpoint starts telling an agent to run it.

**Registering is not the same as registering correctly.** An entry is only an entry for the spelling it matches: the guard matches the literal path as written, with no canonicalization, so a row in one invocation form does not admit a command spelled in another. A tool can therefore hold a row and still be unreachable from the command its own spec prescribes — which is the shape this obligation actually fails in, more often than an absent row. The canonical form set, the two per-tool exception forms and the bar each exception must clear are stated once, in the per-tool form convention block at the head of `core/config/allowlists/script-execution-allowlist.txt`. Read the count and the qualifying bars there rather than from any restatement, including this one: a second copy of that list in this file would be a shadow source that drifts from the file the guard actually reads.

**Coverage boundary — four conditions.** The "runtime guard layer" above is a PreToolUse hook, and such a control is in force only when **all four** hold, and not when any one fails: (1) **loading** — the session resolved a settings surface declaring the hook wiring (any session, main or spawned, whose working directory is under the governed workspace root; a session resolving no such surface loads no hooks at all, and one outside the root is excluded by the scope guard); (2) **bypass** — `CLAUDE_HOOK_BYPASS` was not set in the launching environment (layer 1, which exits **both** hook classes, so the security/workflow asymmetry does **not** exist there); (3) **master-activation class** — `security` always enforces, `workflow` is inert while master activation is off; (4) **mode** — most block hooks warn-and-allow in warn mode, a minority are mode-independent. A citation naming fewer than four overstates the coverage. The canonical statement — with the precedence chain and the reasoning behind each condition — is the coverage-boundary section of the subagent security-posture standard in this same directory.

**Why this qualifier belongs in a promotion framework.** "An agent can only invoke what the guard permits" is the premise a promotion decision rests on when it treats the allowlist as the gate that makes a script's reachability reviewable. Where the guard is not in force, the allowlist is a **convention** — it still records intent and still governs review, but it stops being an interlock. Promote on the strength of the convention; do not size a risk on the strength of the interlock without checking the four conditions on the path the script will actually run on.

## §6 Versioning & Deprecation

| Concern | Rule |
|---|---|
| Version metadata | AS2+ scripts whose consumed output is schema-shaped carry `CLI_VERSION` + `SCHEMA_VERSION` ("the contract is the schema" — the blast-radius tracer precedent). Other scripts version through release tags. `core/standards/version-field-semantics.md` governs SKILL.md frontmatter only — it is NOT extended to scripts |
| Deprecation / demotion | A governed change, not a deletion: citation sweep of all discovery anchors (no dangling invoke instructions), allowlist-entry removal, test removal, tombstone note at the next audit re-run. Precedents: the retired deploy-check 15 (retirement recorded where it was registered), the G3-13 tombstone, the emptied harness-artifact roster (`HARNESS_LIST=()` left in place with its extraction note) |
| Demotion reversibility | Mirrors the promotion tiers in the Failure Modes section below, plus the deprecation sweep |
| **Growth path (named follow-up candidates)** | (1) **Discovery-anchor conformance check** — a deploy-check that asserts every AS2+ script has ≥1 governing-doc citation (converts §5's audit-time detection to check-time). (2) **Tracked script-registry spec** — a registry file with per-script rows validated by its own check, the designated evolution once enforcement tooling lands; deferred because a registry without its conformance check violates the register-or-remove rule in `core/standards/duplicate-source-discipline.md`. (3) **Catalog path-resolution check** (worked example SP-4 below) — doubles as the first concrete member of this tooling family. All three are post-v1.09 intake candidates, not shipped surfaces |

## Worked Examples

Both examples inline the substance of executed v1.09 opportunity-inventory rows (`SP-` IDs are the inventory's stable candidate identifiers). Selection criteria: (a) `[SOURCE]`-grade evidence; (b) spread across ≥2 target rungs and ≥2 invocation surfaces; (c) depersonalization-safe; (d) **durable substance** — the example's truth must outlive the release that ships it; anything time-bound is date-stamped as historical motivation.

### SP-1 — DoR content validation (AS0/AS1 → AS2; split promotion)

The Gate 1 intake-readiness check runs per issue at every triage batch and again at the operations-side DoR gate. Its criteria split cleanly on the Check-class axis: six rows are structural-auto (title format, evidence-label presence, AC verb-pattern, priority field, status/stage anchor, template-label match) and four are judgment-recommend (description actionability, proposed-change specificity, AC semantic verifiability, fresh-session implementability).

- **Triggers fired:** T-REP (every triage batch + the DoR gate mode), T-DET (the six structural rows), T-VAR, T-TOK. Counter-signals: none — the gate rows have been stable across multiple shipped releases.
- **Promotion shape:** the six structural rows promote to an AS2 validation tool invoked at the triage and DoR steps; the four judgment rows **stay agent-side** — the tool gathers and asserts, the agent judges. This is the split-promotion rule in its purest form: the gate's own spec already marks the promotable rows `auto` and the retained rows `recommend`.
- **Why AS2, not AS3:** the validation runs at agent discretion inside a stage the agent is executing (caller-type test: agent-invoked → AS2). Wiring it into a deploy-checkpoint would misplace it — intake readiness is a pipeline-stage concern, not a deploy concern.

### SP-4 — Framework-catalog path-resolution check (AS0 → AS3; checkpoint-wiring)

The framework catalog's per-row `canonical_doc` column drives anchor validation, but the validator's semantics treat a missing doc as "nothing to assert" — a row whose path rots is silently skipped, quietly disabling anchor-consistency checking for that framework. Historical motivation (date-stamped): as of `3f91d05` (2026-06-09), 10 of the catalog's 13 INTERNAL rows carried stale pre-restructure paths and were silently skipped; that population was routed for reconciliation as a post-release intake item. The **mechanism** is the durable point: silent-skip semantics on a registry column invert fail-loud — path rot should fail the check, not mute it.

- **Triggers fired:** T-DET (path existence is structural), T-REP (recurs at every catalog append), T-RISK (silent disablement of a governance check). Counter-signals: none — the catalog schema and the checker's semantics are stable.
- **Promotion shape:** extend the existing version-anchor checker (or add a sibling assertion in the same deploy-check) so a non-resolving `canonical_doc` is a reported finding. Caller-type test: the deploy-check engine invokes it → **AS3**, checkpoint-wired; no agent ever has to remember to run it.
- **Why this example:** it demonstrates checkpoint-wiring into an existing governed caller (the cheapest AS3 promotion — no new checkpoint, one new assertion) and it is the first concrete member of the §6 enforcement-tooling growth path.
- **Status:** SHIPPED v2.09 as Check 18d in `core/deploy/tools/check-version-anchors.py` (`check_18d`) — the first concrete member of the §6 enforcement-tooling growth path. A non-resolving `canonical_doc` is now a reported finding (severity P1) flowing through the deploy.sh Check-18 case-arm, warn-mode-initial. Discovery anchor for the `canonical_doc` path-resolution promotion (worked example SP-4 above).

## Failure Modes

Per the 5-field template and category tags in `core/standards/failure-mode-standard.md`; reversibility tiers per `core/specs/reversibility-protocol.md`.

**Premature promotion — PROC**
- **Signature:** a pattern is scripted in the same release that last changed it; the script's flags/paths churn within 2 releases.
- **Conditional:** do NOT promote when the pattern changed within the last 2 releases, because the script ossifies the wrong shape and every consumer inherits the churn.
- **Root cause:** [recency mistaken for stability] → [trigger evaluation skipped the stability counter-signal] → [promotion rides enthusiasm, not evidence].
- **Mitigation:** the §1 counter-signal table is gate-blocking; NEEDS-STABILIZATION readiness class exists precisely for fired-trigger-but-settling patterns.
- **Principal-vs-junior response:** a principal lets a settling pattern bake and codes it NEEDS-STABILIZATION with a re-assess trigger; a junior scripts whatever repeated twice this week.

**Judgment laundering — OUT**
- **Signature:** a judgment-class step (per the gate-criteria Check enum) ships as an end-to-end script; deterministic output masquerades as assessed judgment.
- **Conditional:** do NOT script a judgment-class step end-to-end, because the script's output inherits the authority of the judgment it replaced without performing it.
- **Root cause:** [work-class axis ignored at target-rung selection] → [the mixed-determinism rule not applied] → [full promotion where split promotion was the ceiling].
- **Mitigation:** T-DET is a precondition for full AS2+ promotion; split promotion is the only path for judgment steps (script gathers, agent judges).
- **Principal-vs-junior response:** a principal promotes the evidence-gathering substrate and leaves the verdict to the agent; a junior automates the verdict because the substrate was automatable.

**Shelfware promotion — HAND**
- **Signature:** a promoted script exists, tests pass, and no agent ever invokes it; the next audit codes its discovery anchor NONE.
- **Conditional:** do NOT close a promotion without its discovery anchor landed in the same PR, because uninvoked scripts rot silently — the platform's own audit found exactly one true shelfware instance (an uncited, uncalled AS2 reporter) and several guards invisible on the agent read path.
- **Root cause:** [registration treated as follow-up work] → [anchor deferred past the promoting PR] → [the citing doc never updated; agents keep re-deriving].
- **Mitigation:** §2's anchor-in-the-promoting-PR row is REQUIRED; Stage 9 review verifies via the promotion decision line; the §4 audit re-run catches survivors.
- **Principal-vs-junior response:** a principal treats the citation as part of the promotion's definition of done; a junior ships the script and files a doc-update ticket that never lands.

**Drift-blind enforcement — TRIG**
- **Signature:** an AS4 guard flips to enforce without warn-log review; false positives block legitimate work platform-wide.
- **Conditional:** do NOT flip a new AS4 guard to enforce without the warn-mode shakedown and log review, because a guard's false-positive rate is unknowable until real traffic exercises it.
- **Root cause:** [enforcement eagerness] → [shakedown discipline skipped] → [allowlist gaps discovered by blocked work instead of log review].
- **Mitigation:** §3's AS4 row makes the shakedown REQUIRED; the hook-layer reference owns the flip checklist.
- **Principal-vs-junior response:** a principal reads the warn logs and seeds the allowlists before enforcing; a junior enforces on day one and triages the blockage reports.

**Promotion/demotion reversibility tiers:** AS0/AS1→AS2 **CHEAP** (one tracked file + anchor; git revert). →AS3 **MODERATE** (checkpoint coupling — the consuming check's expectations bind). →AS4 **MODERATE + shakedown** (operator-facing block risk; the warn→enforce window is part of the cost). Demotion mirrors the same tiers plus the §6 deprecation sweep.

## Cross-references & Cutover

| Surface | Role for this framework |
|---|---|
| `core/standards/failure-mode-standard.md` | The 5-field template + category tags the Failure Modes section conforms to |
| `core/specs/reversibility-protocol.md` | The CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE tiers the per-rung promotion/demotion costs cite |
| `core/schemas/gate-criteria-spec.md` | The Check enum (structural/metrics/judgment) — the work-class axis the ladder composes with; T-DET reads it |
| `core/specs/autonomy-tiers.md` | The prefixed-tier discipline and the WHO-acts axis; the disambiguation table this ladder's `AS` prefix keeps clean |
| `core/standards/upstream-reference-catalog.md` | The upstream skill-creator entries grounding §5's skill-bundled convention (`aligned` verdict) |
| `core/standards/canonical-skill-structure.md` | Skill-structure governance; absorption of §5's skill-citation convention into it is a named follow-up |
| `core/standards/duplicate-source-discipline.md` | The register-or-remove rule deferring §6's registry growth path until its check ships |
| `core/rules/bypass-mode-readiness.md` | The hook-layer shakedown discipline §2/§3 require at AS4 |
| `core/specs/framework-catalog.md` | This framework's registry-of-record row (Check 18-validated) |

**Cutover.** The framework governs promotion decisions going forward. The audit and inventory that ground it are point-in-time operator-instance analysis artifacts (read-once, per the analysis-folder convention); this standard inlines their durable substance and carries no live link to them.

| Version | Date | Change |
|---|---|---|
| v1.09 | 2026-06-11 | Initial framework — AS0–AS4 ladder (ADR-020), six governed sections, worked examples SP-1/SP-4, failure modes |

## References

The issue numbers below are provenance for this record; the prose above leads with self-describing content so the meaning survives renumbering. This block is the designated reference home.

- The framework work item — audit, opportunity inventory, and this governance framework as three chained deliverables: #187.
- The DoR content-validation intake item that worked example SP-1 maps as a case study: #287.
- The triage-analysis-mode intake item that inventory candidate SP-2 maps as the skill-mode-vs-script boundary case study: #286.
- The dual-format document-model intake item recorded as a documented exclusion in the v1.09 inventory (zero live-roster occurrences of its executor sliver at audit): #234.
- The pipeline-engine-and-automation epic this framework is a foundation block within: #573.

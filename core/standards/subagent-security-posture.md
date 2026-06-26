<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Subagent Security Posture — Hub-Orchestrated Autonomous Spawning

**Origin:** monolith-cleanup release
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md)
**Primary consumers:** Hub Procedure 3 Spoke Launch (per [`hub-spoke-bridge.md § Spoke Launch Mechanisms`](../../release/references/how-to/hub-spoke-bridge.md)); all `.claude/agents/*.md` definitions; the autonomy-ceiling PreToolUse hook `block-autonomy-ceiling.sh` (§ 4 Hook Contract — RESOLVED in v2.07)
**Secondary consumers:** [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) (composes-with at hook-layer seam); [`autonomy-tiers.md § Outbound consumers`](../specs/autonomy-tiers.md) (cites this doc as the named outbound consumer)
**Status:** Canonical
**Introduced:** monolith-cleanup release

---

## § 1. Purpose + Scope

The shift from `spawn_task` chip-launched spokes to in-session Agent-tool orchestration changes the security posture for autonomous subagent execution. Under the legacy `spawn_task` chip model, each spoke was operator-initiated via a per-spoke click — an implicit per-spawn operator gate. Under in-session Agent-tool orchestration, the hub spawns subagents inline without operator click, expanding the autonomous-execution surface.

This standard **codifies** the security posture that protects autonomous subagent execution. It does **not** introduce new enforcement at this release — the operative enforcement surface (frontmatter `tools:` enumeration + the 5 PreToolUse hooks + the Recursion-Prohibited preamble + the Return Value escape path) already exists as the de facto state of the platform. This release makes that posture canonical in writing; it does not add new gates.

**Release scope (monolith-cleanup, documentation only):**
- 4 operative mechanisms documented as the canonical security model
- 1 deferred mechanism (Autonomy-Tier-aware PreToolUse hook) carried in this doc as a **contract** for a follow-up release to implement
- Cross-reference appends in 4 sibling files (no enforcement change)

**v2.07 update — the deferred Hook Contract is RESOLVED:** the Autonomy-Tier-aware
PreToolUse hook shipped in v2.07 as **`block-autonomy-ceiling.sh`** (#1163),
**payload-triggered** (NOT subagent-session-detection — that trigger was infeasible;
see § 4). It enforces the irreducible-Tier-0 floor + the `automation_level` ceiling.
See § 4 for the resolved contract.

**Still deferred (Phase 2)** — the empirical-verification suite has since run (see the §1 empirical-suite outcome below: hook-inheritance confirmed at workspace root, worktree-session hook-loading carried to #1472); the items that remain deferred are:
- The subagent-only approval-evidence gating rows of the § 4 rule table (Tier-1/2/3 "ALLOW only if approval evidence / cascade_scope / standing authorization") — they need a session/approval signal the tool-call payload does not carry (the same unavailable-signal problem that sank the subagent-session trigger). Revisitable when/if `subagent_type` + an approval-evidence input become readable.
- `pipeline-event-log.md` `event_subtype: subagent-invocation` substrate extension (closed-enum governance change)

**§1 empirical-suite outcome — hook-inheritance CONFIRMED at workspace root; worktree-loading verification → #1472 (v2.23, #189):**
- The former "One-time empirical verification suite (Stage 7 DT regression cases)" deferral is **discharged with a partial result in v2.23 (#189).** Hook-inheritance and frontmatter-enforcement coverage shipped as a two-layer probe: a deterministic CI logic-regression (`core/hooks/tests/subagent-hook-inheritance.test.sh`, the 6 hook patterns, gated by the `install-tests` hook-tests job) PLUS a manual operator-run live-delivery procedure (`core/hooks/tests/subagent-hook-inheritance-probe.md`). The Layer-B probe ran one pattern (`git push --force` → BLOCK-DESTRUCTIVE-001) at workspace root and confirmed delivery: a subagent's tool call was intercepted before execution. **Inheritance verification is therefore done** — a subagent inherits whatever PreToolUse hooks its session has loaded. The remaining open question is worktree-session hook-LOADING (whether a session launched from a repo/worktree cwd loads hooks at all), which the workspace-root probe cannot settle; it is tracked as **#1472 (OPEN)**. See § 3 Mechanism 2 + ADR-041.

**Reflexive-scope discipline:** This release IS orchestrated by the Agent-tool subagent mechanism this standard documents. Applying the standard to its own Stage 5 / 6 / 7 / 8 spokes would create a reflexive-pipeline loop. § 8 Cutover encodes this exemption.

---

## § 2. Definition — "Autonomous Subagent Spawning"

| Spawning class | Mechanism | In-scope this standard? |
|---|---|---|
| Hub-spawned spokes via Agent tool | [`hub-spoke-bridge.md § Spoke Launch Mechanisms — Default`](../../release/references/how-to/hub-spoke-bridge.md) | YES |
| Hub-spawned chips via `mcp__ccd_session__spawn_task` (legacy) | `mcp__ccd_session__spawn_task` | NO (deprecated) |
| Recursive sub-subagent spawn from a spoke | (PROHIBITED per § 3.4 Recursion-Prohibited mechanism) | NO (prohibited surface) |
| Scheduled-task agents | (no current substrate) | NO (out of scope; future addition would amend this standard) |
| **Parent hub session (operator-launched Claude Code, BASE state)** | Operator-launched `claude` invocation | **NOT a subagent — baseline session.** IN-SCOPE for the hook surface (§ 3.2) and escape-path mechanism (§ 3.4 Layer-5-equivalent); frontmatter binding (§ 3.1), audit-trail contract (§ 3.3 deferred), and recursion-prohibition (§ 3.4) do not apply (no agent definition file; no parent-spoke linkage; the parent IS the recursion-source by design) |

**Why the baseline row matters:** A reader could infer from a spawning-class-only enumeration that the security layers in § 3 apply ONLY to subagents and that parent-session hub Bash invocations are exempt. They are not. The 5 PreToolUse hooks fire identically on parent-session tool calls. The baseline row pre-empts that under-scope drift per adversarial finding FMF-5 (surfaced at review).

---

## § 3. The 4-Mechanism Security Posture

> **Honest count discipline (per adversarial finding CDF-3):** This standard documents **4 independent enforcement mechanisms**, not 5 separate layers. The Stage 5 spec originally described a 5-layer model; the adversarial review identified that the "Layer 4 — Recursion-Prohibited Preamble" recapitulates the Layer 1 (tools-list exclusion) mechanism in prose form rather than constituting an independent enforcement layer. This standard adopts the 4-mechanism framing and surfaces the prose-recap as part of Mechanism 1's belt-and-suspenders disclosure. Defense-in-depth claims are easier to verify when independent mechanisms are counted accurately.

### Mechanism 1 — Frontmatter `tools:` Allowlist + Recursion-Prohibited Reminder (Persona Binding)

**Structural enforcement:** Every `.claude/agents/<name>.md` MUST declare a `tools:` field enumerating the exact tool set the persona is authorized to invoke. Tools omitted from the list are unauthorized.

**Canonical two-pattern enumeration (current state — empirically surveyed 2026-05-27 at commit `2e0ee70`):**

| Pattern | Tool list | Applied to (5 read-only + 3 write-capable) |
|---|---|---|
| **Read-only (11 tools)** | `Read, Grep, Glob, LS, Bash, WebFetch, TodoWrite, WebSearch, KillShell, BashOutput, NotebookRead` | `pmo-release-planner`, `pmo-solutioning`, `pmo-adversarial`, `pmo-dev-testing`, `pmo-qa-testing` |
| **Write-capable (14 tools)** | Read-only + `Edit, Write, NotebookEdit` | `pmo-engineering`, `pmo-execute`, `pmo-close` |

**Variance discipline (per adversarial finding PRF-3):** Two distinct patterns are NOT zero drift. They ARE intentional, role-aligned variance — review/analysis personas (Stages 4/5/7/8 + adversarial) bind to read-only; execution personas (Stages 6/12/13) bind to write-capable. The two-pattern partition IS the canonical structure; the variance IS the design.

**Uniform exclusions across BOTH patterns (recursion-prohibition surface — structural):**
- `Agent` tool — absent from all 8 persona definitions
- `mcp__ccd_session__spawn_task` — absent from all 8 persona definitions

**Behavioral reinforcement (recursion-prohibition surface — prose):** Every spoke prompt carries a `Recursion prohibited: do NOT invoke the Agent tool or spawn_task` preamble per [`hub-spoke-bridge.md § Recursion prohibited`](../../release/references/how-to/hub-spoke-bridge.md). This is a **reminder** that recapitulates the structural exclusion above, not an independent enforcement layer. The structural defense lives in the tools-list omission; the prose reminder strengthens spoke-comprehension at zero structural cost.

**Enforcement contract (per Stage 5 D-ToolRestrictionContract):** Frontmatter `tools:` is treated as **DECLARATIVE-AT-MINIMUM**. Anthropic upstream Agent-tool semantics for the `tools:` field are non-canonical at the time of writing — whether the harness STRUCTURALLY refuses tool calls outside the list, or whether the list is operator-facing documentation only, is empirically undetermined. Defense-in-depth requires BOTH frontmatter declaration AND Mechanism 2 hook enforcement.

**Empirical-verification gap (per adversarial finding PRF-2):** Whether Mechanism 1 is structurally enforced or merely documentary is **answerable** by an unprivileged out-of-list tool-call probe (e.g., a read-only spoke attempting a benign `Write` to a temp file). The test is **NOT** a security probe; it is a boundary-interrogation test. This standard prescribes the empirical test as a Stage 7 DT regression case in a follow-up release (scope-bound to the § 4 Hook Contract).

### Mechanism 2 — PreToolUse Hook Inheritance (Existing 5-Hook Surface)

**Operative mechanism:** The 5 PreToolUse hooks most relevant to subagent tool-call interception (`block-destructive`, `block-egress`, `block-mcp-writes`, `block-credential-reads`, `block-rm-prefer-trash`) operate at SESSION level per the bypass-mode hook registry's [`§ The Hooks`](../rules/bypass-mode-readiness.md) table (the full registry is 7 bypass-mode hooks; this mechanism cites the 5 whose matchers a spawned spoke can trip). The hooks read tool-call payloads from stdin; they do NOT read session-context fields (no `session_id`, no `parent_session`, no `subagent_type`). The hooks fire on the tool-call payload itself regardless of which session-class (parent or subagent) emitted the call.

**Evidence basis (LOGICAL-INFERRED, EMPIRICAL VERIFICATION DEFERRED — per adversarial finding PRF-1 / FMF-4):** The session-level enforcement model means subagent tool calls fire the same hooks transparently **by construction** — the hooks consume tool-call payloads from stdin and have no notion of caller class. However, the claim "the harness DELIVERS subagent tool calls to the hook in the first place" is not yet empirically verified by an end-to-end test. This standard prescribes a Stage 7 DT regression suite (one test per hook: subagent attempts each of the 5 hook-triggering patterns; observe blocks) as a follow-up activity. Until the empirical suite runs, treat Mechanism 2 as **LOGICAL-INFERRED-UNTIL-EMPIRICALLY-TESTED**.

**Mechanism 2 (hook-inheritance) — CONFIRMED at workspace root (v2.23, #189).** The "LOGICAL-INFERRED-UNTIL-EMPIRICALLY-TESTED" qualifier above is superseded for the workspace-root case. Evidence: (a) the Layer-A CI regression suite (6 cases, `core/hooks/tests/subagent-hook-inheritance.test.sh`) confirms each hook's logic fires on subagent-shaped payloads; (b) a Layer-B probe confirmed delivery — a subagent spawned from a workspace-root session attempting `git push --force` was intercepted by `block-destructive` (BLOCK-DESTRUCTIVE-001) before execution. A subagent's tool calls are subject to whatever PreToolUse hooks its session has loaded. (ADR-041 records the two-layer-probe decision.)

**Residual — worktree-session hook-LOADING is UNTESTED (#1472, OPEN).** The Layer-B probe covered a single pattern at workspace root, where hooks are loaded; it did not establish whether hooks LOAD for a session launched from a repo/worktree cwd (a hook-loaded session cannot observe its own absence; that test needs a session started from the repo). #1472 is the open gap — PreToolUse hooks are wired in the workspace-root settings only. Inheritance is confirmed; whether a worktree session has any hooks to inherit is #1472's question. Real Mechanism-2 enforcement for a spoke — which runs in a worktree — therefore remains gated on #1472. The Layer-B probe (`core/hooks/tests/subagent-hook-inheritance-probe.md`) is the standing re-test for when #1472 lands.

**Anti-injection guarantee inheritance:** [`BLOCK-DESTRUCTIVE-023`](../rules/bypass-mode-readiness.md) fires on all Bash invocations including those from subagents. The asymmetry (operator pre-launch shell can enable the bypass env var; prompt-injection cannot) holds for in-session Agent-tool subagent invocations by construction. Same evidence basis: LOGICAL-INFERRED; Stage 7 DT regression case prescribed per Stage 5 spec D-AntiInjectionReverification option C.

### Mechanism 3 — Audit-Trail Capture (CONTRACT-ONLY in this release; substrate extension DEFERRED to follow-up release)

> **Heading-level deferral disclosure (per adversarial finding FMF-3):** This mechanism is described as part of the canonical posture, but the substrate extension that operationalizes it is NOT shipped in this release. The contract lives in this section; the implementation is a follow-up release deliverable.

**Future mechanism:** Subagent invocations will log to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) via the existing `append-pipeline-event.sh` substrate. The audit-trail will capture: `parent_spoke_id`, `subagent_type`, `model`, `isolation`, `verdict`, `ts_iso`.

**Substrate extension contract (deferred):**
- `event_type: decision` (existing — the closest semantic neighbor; subagent invocation IS a hub decision to delegate work)
- `event_subtype: subagent-invocation` (NEW — closed-enum extension)
- `payload` shape: `parent:#N; sub:#M; persona:pmo-solutioning; model:opus; isolation:worktree; verdict:PASS`

Adding the subtype requires a governance change per [`pipeline-event-log-schema.md § 3`](../../release/references/standards/pipeline-event-log-schema.md) (closed-enum). DEFERRED to follow-up release per Stage 5 spec D-DeferredHookGate. Until the substrate extension lands, parent-spoke ↔ subagent linkage is reconstructable from the sub-task comment trail (Procedure 4 post-completion comment + sub-task assignee + GitHub Issue parent-child relationship), which is sufficient for audit but not for queryable event-log analysis.

### Mechanism 4 — Escape-Path Semantics (No Silent Failures)

**Operative mechanism:** When a subagent triggers a hook block mid-execution, the spoke detects the non-zero exit code from the tool call and emits `verdict: BLOCKED` per its Return Value to Hub schema (see [`hub-spoke-bridge.md § Return Value to Hub`](../../release/references/how-to/hub-spoke-bridge.md)). The hub catches the return and routes via Tier 2 `[SCOPE CHANGE]` per [`.claude/rules/release-process.md § Inter-Stage Feedback Protocol`](../../release/governance/release-process.md).

**Worked example:**

```
1. Spoke attempts a destructive git operation (e.g., `git push --force`)
2. block-destructive.sh BLOCK-DESTRUCTIVE-001 fires; tool call exits non-zero
3. Spoke catches the exit code; emits Return Value:
     verdict: BLOCKED
     sub-task: #N (open-blocker)
     comment: <URL>
     next: block:operator-decision-at-stage-{N}
4. Hub reads the return value; surfaces Decision Briefing for operator
5. No silent failure; no hook bypass; no privilege escalation
```

**Exit-code propagation gap (per adversarial finding FMF-1):** The Layer 5 contract assumes the spoke can DISTINGUISH a hook block from a generic tool-call failure in its context window. The harness propagation chain (PreToolUse hook → tool_result → LLM-visible message) is not yet empirically characterized — the spoke MAY observe "tool failed" without the BLOCK-DESTRUCTIVE-001 context and emit `verdict: PASS` (the silent-failure case Mechanism 4 is designed to prevent).

**Mitigation:** Spoke prompts SHOULD include an explicit detection step: "If a tool call fails for any reason, check `.claude/hooks/block-log.jsonl` tail before emitting `verdict: PASS`." This makes the hook-block detection an explicit step in the spoke's process rather than relying on harness propagation alone. Adding this step to the Spoke Template preamble is a follow-up activity (carry-forward).

---

## § 4. Hook Contract (RESOLVED in v2.07 — `block-autonomy-ceiling.sh`)

> **Supersession (R-C5RECON, v2.07):** This section originally proposed
> `block-subagent-tier-violation.sh`, triggered on **subagent-session detection
> via session context**. That design was **infeasible against the actual hook
> input** — § 3 Mechanism 2 of THIS document states the hooks "do NOT read
> session-context fields (no `session_id`, no `parent_session`, no
> `subagent_type`)", and the empirical hook survey found zero hooks in the suite
> reading any session/subagent field. A hook triggered on a signal the hook layer
> cannot read would be a false-enforcement floor. The v2.07 design (#1163)
> triggers on the **tool-call payload** — the universal signal all hooks already
> use — and reads the `automation_level` ceiling. The supersession decision is
> recorded in [`ADR-031`](../ADRs/ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md).

**Hook:** `.claude/hooks/block-autonomy-ceiling.sh` (shipped v2.07, #1163).

**Trigger:** PreToolUse on any **mutation tool call** — matchers `Bash`, `Write`,
`Edit`, `mcp__.*`. (Read / WebFetch are non-mutating and out of scope.) Fires on
the tool-call payload, NOT on session context — so it gates parent-session AND
subagent-session calls identically (per § 2's baseline row, the hook surface
includes parent-session calls), without depending on the unreadable
`subagent_type` field.

**Reads:** `automation_level` from `operator.toml` (the runtime-read precedent —
`notify-version-skew.sh`), resolved ONCE at SessionStart by
`prime-autonomy-ceiling-cache.sh` and cached at
`${HOME}/.cache/pmo-platform/autonomy-ceiling`; the PreToolUse hook reads the
cache (a single file read), falling back to a direct resolve when the cache is
absent. The numeric ceiling maps `{off:0, recommend:1, bounded_auto:2}`.

**Rule contract (Autonomy-Tier-aware gating per [`autonomy-tiers.md § Outbound consumers`](../specs/autonomy-tiers.md)):**

| Action class | Hook posture | v2.07 status |
|---|---|---|
| **Tier 0 (Manual / Irreducible Human Tasks)** | BLOCK regardless of `automation_level` AND regardless of mode (always-enforce class, mirrors `block-rm-prefer-trash` permanence). Checked FIRST. | **LIVE** — but only for the **payload-detectable** subset: governance-file writes + cross-domain bridge writes (resolved from the Write/Edit `file_path` + `cwd`). Financial / account-creation / security-permission and the Stage 9 / Stage 12 gates are NOT mechanically detectable from a tool payload — they stay **operator-irreducible by convention**, documented but not hook-enforced. Item 8 (destructive outside the workspace) is already owned by `block-rm-prefer-trash` BLOCK-TRASH-001/003 — C5 does NOT duplicate it. |
| **Ceiling check (all mutations)** | Block (mode-gated) iff the action's required tier EXCEEDS the resolved ceiling (`effective = min(ceiling, required)`). **Permissive default: an unmapped action is ALLOWED** — C5 gates every mutation, so a deny-default would break the platform; the un-gated action still runs through the existing safety hooks. Required tier comes from a conservative declared-mapping table seeded from `autonomy-tiers.md` observable indicators (governance path → Tier 0; `08-Generated/` staging → Tier 2; stakeholder-facing write → Tier 1; `mcp__*` write-verb → Tier 1). | **LIVE** under the hook's own mode (warn-initial). |
| **Tier 1 (Recommend / drafts)** — subagent approval-evidence row | ALLOW only if approval-evidence comment present on parent sub-task | **Phase-2 deferred** — needs a session/approval signal the payload lacks |
| **Tier 2 (Bounded Auto / `cascade_scope`)** — subagent row | ALLOW only if action target is within declared `cascade_scope` of upstream Tier 1 artifact | **Phase-2 deferred** — same unavailable signal |
| **Tier 3 (Autonomous / standing authorization)** — subagent row | ALLOW only if standing-authorization clause is named in spoke prompt prelude | **Phase-2 deferred** — same unavailable signal |

**Initial posture:** warn-mode via the hook's **OWN** mode file
`.claude/hooks/.autonomy-mode` (NOT the shared `.mode` — C5 has the highest
false-positive risk of any hook, so its shakedown→enforce lifecycle is decoupled
from the shared-`.mode` cohort; ships `.autonomy-mode.template` = `warn`). The
ceiling check logs to `.claude/hooks/autonomy-warn-log.jsonl` in warn-mode and
exits 0; the Tier-0 floor always blocks regardless of mode. Flip-to-enforce after
2-3 release shakedown per [`bypass-mode-readiness.md § Shakedown → Enforce
Transition Checklist`](../rules/bypass-mode-readiness.md). **Do NOT read the dial
as "now hard-enforced" unqualified** — the ceiling check is hard only after the
operator flips this hook warn→enforce; the Tier-0 floor is live for the
payload-detectable classes only.

**Status:** RESOLVED in v2.07 (#1163). Tier-0 floor + ceiling check shipped; the
subagent-only approval-evidence rows (Tier-1/2/3 above) are Phase-2 deferred.

**Follow-up filing recommendation:** Stage 13 Close spoke files a carry-forward `improvement.yml` issue for the Phase-2 subagent-approval-evidence gating (when `subagent_type` + an approval-evidence input become readable; pairs with the `pipeline-event-log.md` `event_subtype: subagent-invocation` substrate extension), with labels `cluster: security`, `protocol`, `size:L`. Target follow-up milestone TBD at next-release planning.

### Counter-design considered (per adversarial finding CDF-2): Deploy-time `tools:` conformance check

An alternative to (or complement to) the runtime hook above is a **deploy-time `deploy.sh --check`** addition (`agent-tools-list-conformance`) that validates `.claude/agents/*.md` `tools:` enumeration against the two-pattern canonical (read-only vs write-capable, role-aligned partition). The check would fire at every deploy and every session-start drift check, catching:

- An agent file shipping with `Agent` in its `tools:` list (FM-1)
- An agent file omitting the `tools:` frontmatter field entirely
- An agent file diverging from its role-aligned canonical pattern

This counter-design sidesteps the unknown-upstream-semantic gap entirely: regardless of whether the harness STRUCTURALLY enforces `tools:` omissions at runtime, the deploy check catches authoring-time drift. Same pattern as Check 6 (canonical-structure compliance) and Check 10 (editor audit-trail) — platform-native structural checks that do not depend on upstream behavior. RECOMMENDED for the follow-up release alongside the runtime hook above.

---

## § 5. Composition with Existing Standards

| Standard | Composition direction |
|---|---|
| [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) | Composes-with at Mechanism 2 (subagent inherits hook surface); cross-referenced from that file's § Related |
| [`autonomy-tiers.md`](../specs/autonomy-tiers.md) | This doc IS the named outbound consumer of "Future PreToolUse hooks — Tier-based gating"; § 4's contract is REALIZED in v2.07 as `block-autonomy-ceiling.sh` (#1163) — autonomy-tiers.md § Outbound consumers annotates the "Future PreToolUse hooks" row with the resolved hook name + payload trigger |
| [`hub-spoke-bridge.md § Spoke Launch Mechanisms`](../../release/references/how-to/hub-spoke-bridge.md) | This doc is the security-posture documentation cross-referenced from § Spoke Launch Mechanisms |
| [`agent-handoff-framework.md`](agent-handoff-framework.md) | Composes-with at Mechanism 3 (handoff manifest carries persona; persona binds to tools) |
| [`decision-discipline.md`](../disciplines/decision-discipline.md) | Composes-with at Mechanism 1 (cascade rules inform recursion-prohibition; FM-3 self-elevation is the canonical anti-pattern) |
| [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) | Future schema extension for Mechanism 3 audit-trail subtype |
| [`upstream-reference-catalog.md`](upstream-reference-catalog.md) | When populated with an entry for "Anthropic Agent tool `tools:` field semantics", this doc references it to resolve the Mechanism 1 DECLARATIVE-vs-ENFORCING question |

---

## § 6. Failure Modes (per [`failure-mode-standard.md`](../specs/failure-mode-standard.md) 5-field template)

### FM-1 — Subagent attempts recursive spawn — TRIG

- **Signature:** Subagent invocation prompt includes `Agent(...)` or `spawn_task(...)` call
- **Conditional:** Do NOT include `Agent` tool in any persona's `tools:` enumeration, because subagent recursion produces orphan sessions and unbounded blast radius
- **Root cause:** Tool-list enumeration omits the recursion-exclusion check; OR the operator authors a new agent definition and copies a template that includes `Agent`
- **Mitigation:** Mechanism 1 tools enumeration uniformly excludes `Agent` + `spawn_task`; the prose preamble recap reinforces; deploy-time conformance check (deferred per § 4 counter-design) would catch authoring-time drift
- **Principal-vs-junior response:** Junior — adds `Agent` to tools list "for completeness"; Principal — names the recursion-prohibition contract and excludes by design

### FM-2 — Bypass env var set in subagent Bash invocation — INPUT

- **Signature:** Subagent emits Bash invocation containing the bypass env-var-set pattern (e.g., `CLAUDE_HOOK_BYPASS=1 <command>`)
- **Conditional:** Do NOT assume `BLOCK-DESTRUCTIVE-023` anti-injection applies only to parent session, because the hook fires at session-level on every Bash invocation regardless of caller class
- **Root cause:** Operator misreads "mid-session" as parent-only; subagent IS a session-level continuation
- **Mitigation:** Mechanism 2 hook fires identically; documented in this standard; empirical Stage 7 DT regression case prescribed
- **Principal-vs-junior response:** Junior — questions whether subagents inherit the rule; Principal — traces session-level hook inheritance and confirms by construction

### FM-3 — Spoke verdict masks hook block — OUT

- **Signature:** Spoke catches hook-block exit code but emits `verdict: PASS` (silent failure)
- **Conditional:** Do NOT emit `verdict: PASS` when ANY tool call returned non-zero from a hook block, because `PASS` without blocker context misroutes the hub
- **Root cause:** Spoke conflates "completed work despite block" with "successfully completed"; OR the harness fails to propagate hook-block context to the spoke's tool_result and the spoke cannot distinguish hook-block from transient failure (FMF-1 exit-code propagation gap)
- **Mitigation:** Mechanism 4 escape-path semantics; spoke MUST emit `verdict: BLOCKED` on any hook-block exit; explicit `.claude/hooks/block-log.jsonl` check step in spoke preamble (follow-up activity per § 3 Mechanism 4 mitigation)
- **Principal-vs-junior response:** Junior — emits `PASS` to keep release moving; Principal — emits `BLOCKED` with `next: block:operator-decision-at-stage-{N}` and surfaces blocker via comment

### FM-4 — Subagent declares non-canonical `tools:` enumeration — PROC

- **Signature:** A `.claude/agents/<name>.md` ships with a `tools:` field that omits required role-aligned tools OR adds disallowed tools (e.g., `Agent`, `spawn_task`, or a role-mismatched write tool on a review persona)
- **Conditional:** Do NOT author a new agent definition without consulting the canonical two-pattern enumeration in Mechanism 1, because role-aligned variance is the design and ad-hoc enumeration breaks the partition
- **Root cause:** New agent author treats `tools:` as a per-persona choice rather than a role-aligned canonical
- **Mitigation:** This standard codifies the two-pattern enumeration; deploy-time conformance check (per § 4 counter-design, deferred) would block authoring-time drift; until the check ships, PR reviewer inspects new agent files against the canonical
- **Principal-vs-junior response:** Junior — enumerates tools based on persona description; Principal — selects the read-only or write-capable canonical based on persona role and applies it verbatim

---

## § 7. Cross-Reference

- [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) — Mechanism 2 hook surface authority; `BLOCK-DESTRUCTIVE-023` anti-injection rule; CLAUDE_HOOK_BYPASS escape hatch semantics
- [`autonomy-tiers.md`](../specs/autonomy-tiers.md) — Tier classification (0/1/2/3) + named outbound consumer relationship for the § 4 Hook Contract (RESOLVED v2.07 as `block-autonomy-ceiling.sh`)
- [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) — § Spoke Launch Mechanisms (Mechanism 1 frontmatter + Mechanism 4 escape-path); § Recursion prohibited (Mechanism 1 prose recap); § Return Value to Hub (Mechanism 4 closed-enum)
- [`agent-handoff-framework.md`](agent-handoff-framework.md) — Handoff manifest persona binding (composes with Mechanism 1 persona-to-tools binding)
- [`decision-discipline.md`](../disciplines/decision-discipline.md) — FM-3 self-elevation anti-pattern parent
- [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) — Future Mechanism 3 substrate extension target (closed-enum `event_subtype: subagent-invocation`)
- [`upstream-reference-catalog.md`](upstream-reference-catalog.md) — Target home for the Anthropic Agent-tool `tools:` field semantic verification (per § 3 Mechanism 1 DECLARATIVE-AT-MINIMUM enforcement contract)

---

## § 8. Cutover

Applies to releases entering Stage 5 strictly AFTER the merge SHA recorded in [`release/releases/RELEASE_LOG.md`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>). **The introducing release itself is exempt** per reflexive-pipeline-loop discipline — the release IS orchestrated by the Agent-tool subagent mechanism this standard documents; applying the standard to its own Stage 5 / 6 / 7 / 8 spokes would create a footgun where the rule shipping in THIS release would fire on THIS release's own orchestration. Subsequent releases adopt the 4-mechanism posture as canonical.

---

## § 9. Version History

| Version | Date | Change |
|---|---|---|
| monolith-cleanup | 2026-05-27 | Initial authoring (Tier-A NEW agent-process artifact); documentation + tool-restriction patterns ONLY; Deferred Hook Contract carried for follow-up release; 4-mechanism framing adopted per adversarial finding CDF-3 (consolidating original 5-layer model's Layer-1 + Layer-4 into Mechanism 1) |
| v2.07 | 2026-06-19 | § 4 Hook Contract RESOLVED (R-C5RECON, #1163): renamed `block-subagent-tier-violation.sh` → `block-autonomy-ceiling.sh`, re-scoped the trigger from subagent-session-detection (infeasible — contradicted by § 3 Mechanism 2's "hooks do NOT read session-context fields") to the tool-call payload; Tier-0 floor + ceiling check shipped LIVE (payload-detectable Tier-0 classes only — governance-file + cross-domain writes); subagent-only approval-evidence rows (Tier-1/2/3) Phase-2 deferred; own mode file `.autonomy-mode` (warn-initial). Supersession recorded in ADR-031. |
| v2.23 | 2026-06-25 | Phase-2 empirical-verification suite SHIPPED (#189): the deferred one-time suite is replaced by a TWO-LAYER probe — a deterministic CI logic-regression (`core/hooks/tests/subagent-hook-inheritance.test.sh`, 6 hook patterns) + a manual operator-run live-delivery procedure (`core/hooks/tests/subagent-hook-inheritance-probe.md`), per ADR-041. Layer-B probe RESULT recorded: hook-inheritance CONFIRMED at workspace root (a subagent's `git push --force` intercepted by BLOCK-DESTRUCTIVE-001 before execution); worktree-session hook-LOADING remains UNTESTED and is carried to #1472 (OPEN) — the probe ran a Desktop-app session and could not exercise a repo-launched session. § 1 outcome bullet + § 3 Mechanism 2 record the confirmed-at-root finding and the #1472 residual. ADR-041 pairs with ADR-031. |

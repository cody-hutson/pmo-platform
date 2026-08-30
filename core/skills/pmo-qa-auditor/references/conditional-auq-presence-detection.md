---
title: Conditional-AUQ-Presence Detection (G11) — PMO QA Auditor Reference
purpose: The detection reference for pmo-qa-auditor gate G11 — flagging a manufactured or a missing conditional AskUserQuestion operator-decision gate.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Conditional-AUQ-Presence Detection (G11) — PMO QA Auditor Reference

## Purpose

This file is the full specification for **G11 — Conditional-AUQ-Presence Verification**,
the Mode A gate `pmo-qa-auditor` fires when the output under audit is an
**ask-when-ambiguous-tier skill's output or transcript**. G11 verifies that an
`AskUserQuestion` (AUQ) invocation trace is present **when the trigger-match heuristic did
not resolve a unique mode** (the input was ambiguous), and is correctly **absent** when the
heuristic resolved a unique mode. It is the audit-time detector for the failure mode where a
future edit silently removes a skill's `## Mode Selection` fallback, so a mode gets chosen
without the operator being asked — caught by a gate rather than by manual observation.

G11 is the structural analogue of **G7** (SKILL.md-scoped, two-phase, deterministic Phase 1)
and **G8** (cascade-sweep-scoped, two-phase). All three are file-type-conditional gates inside
Mode A that push the irreducibly-judgment call to an LLM-graded Phase 2 and keep only the
mechanical checks in a deterministic Phase 1. G11 fires on an ask-when-ambiguous-tier skill
transcript; the SKILL.md G11 gate definition (Mode A Process step 3) points here for the full
tables.

**Authoritative cross-references:**
- `../../governance/OPERATIONS.md` § Mode Selection Protocol — the **single source of truth**
  for the ask-when-ambiguous roster (the regression set) and the three-tier classification.
  G11 **reads** this roster live; it does **not** hardcode the skill names (see § 3).
- `../../standards/failure-mode-standard.md` — the domain-specific failure-mode discipline; the
  auditor's own § Domain-Specific Failure Modes carries an INPUT entry (roster-hardcode)
  documenting G11's most likely regression.

---

## 0. Substrate dependency — G11 is a spec-ahead-of-substrate contract (READ FIRST)

**G11 is specified here as a contract, not asserted as an immediately-runnable gate.** It has an
input-substrate dependency that Mode A does not satisfy today, and honesty about that gap is part
of the spec (the same DOC-ONLY-honesty posture the acceptance-assertion framework took: specify
the contract fully, name the wiring that is not yet built).

**The gap, stated plainly:**

- G11's input is a **transcript that contains AUQ invocation traces plus the originating user
  request** — it needs both the tool-call record (was AUQ invoked?) and the request that the
  trigger-heuristic was resolving (was a trace *required*?).
- **Mode A ingests one output artifact** (`SKILL.md` Mode A **Input**: "One output from any
  operational skill"), **not** a request-plus-trace transcript. And AUQ invocation traces are
  **not persisted as a greppable corpus** — there is no on-disk transcript store the auditor can
  point Phase 1's regex at.
- Therefore G11's Phase 1 detection (`AUQ_TRACE_RE` over the transcript) and Phase 2 adjudication
  (was the input ambiguous?) both presume an input surface that the current Mode A **does not
  receive**. Until that surface exists, G11 is **specified but dormant** — it fires only when a
  caller actually hands Mode A an ask-when-ambiguous-tier transcript with traces (e.g., a future
  transcript-review harness, or a manually-pasted transcript), not on the output-only artifacts
  Mode A reviews today.

**Where the substrate comes from (tracked dependency):** the request-plus-trace transcript input
is the province of the downstream QA-acceptance-review capability — the consumer this card's native
`Blocks` edge points at, milestone-tracked separately (see the Source(s) block below for the issue
reference). That capability ingests transcripts; when it lands, it supplies G11 its input surface.
G11 is authored **ahead** of that
substrate deliberately — the gate spec is the durable artifact; the transcript-ingestion wiring is
a separate follow-on. This is a named residual, not a silent assumption: G11 does **not** claim
"zero blast radius, runs today." It claims "the contract is complete and correct; the input
substrate is a tracked follow-on."

This mirrors G8's own invocation-guarantee caveat (`cascade-completeness-detection.md` § 6): a
QA-time gate gives no unconditional guarantee it will actually be pointed at a qualifying input.
G11 states the stronger version of that caveat — the qualifying input **does not yet routinely
reach Mode A at all**.

---

## 1. The two-phase check

G11 mirrors G7/G8's two-phase structure. **Phase 1 is deterministic** and covers only what can be
mechanically detected from a present transcript: is an AUQ tool-call trace present, and which Step
resolved the mode. **Phase 2 is LLM-graded judgment** — the load-bearing "was a trace *required*?"
call, which a regex cannot make (exactly as G8-01's "should a block exist?" cannot).

> **Determinism boundary (read this before assuming Phase 1 catches the important case).**
> The load-bearing FAIL case — an **ambiguous input that resolved to a mode WITHOUT** an AUQ trace
> (required-but-absent) — is a **Phase-2 judgment, not a deterministic Phase-1 signal.** Phase 1
> can determine *that a trace is absent* (a boolean over the transcript), but it **cannot**
> determine *that a trace was required*, because "required" depends on whether the request was
> ambiguous across ≥2 modes — a semantic re-derivation of the skill's trigger-match table. So the
> absent-and-required FAIL is rendered at Phase 2 (G11-04 → G11-05), precisely as G8-01 renders the
> absent-block case at Phase 2. Phase 1 determinism covers only the **present-but-unnecessary**
> direction (a trace *is* present — a fact Phase 1 can grep — which Phase 2 then judges unnecessary
> if the input was a unique match). An absent trace has no field to grep for "requiredness"; that
> is irreducibly Phase 2.

### Phase 1 — Structural (deterministic; operates on a PRESENT transcript)

| ID | Check | Method | Pass criterion |
|---|---|---|---|
| G11-01 | **Skill-identity + tier resolution.** The reviewed output identifies its producing skill, and that skill is on the ask-when-ambiguous roster. | Match the skill identity from the transcript (frontmatter `name:` echo, invocation header, or a `## Mode Selection` "Tier classification: Ask-when-ambiguous" line) against the roster **read live from OPERATIONS.md § Mode Selection Protocol** (see § 3 — never a hardcoded list). | Skill resolves to a roster member → gate fires; else N/A (does not fire). |
| G11-02 | **AUQ-trace presence detection (the deterministic core).** Detect whether an `AskUserQuestion` **tool-call** trace is present in the transcript. | Regex the transcript with `AUQ_TRACE_RE` (§ 2) — a tool-**invocation** match (`invoke … name="AskUserQuestion"`, a `"name": "AskUserQuestion"` tool_use block, or the `AskUserQuestion(` call token), deliberately **excluding** bare prose mentions of the string (a SKILL.md *documenting* AUQ is not *invoking* it). | Deterministic boolean `trace_present ∈ {true, false}`, with the matched `line:col` cited when true. |
| G11-03 | **Mode-resolution-path capture.** Capture which Step resolved the mode: Step 1 (chain-skip), Step 2 (heuristic unique match), or Step 3 (AUQ fallback). | Regex for the resolution markers: a chained-invocation marker in **either** encoding defined at OPERATIONS.md § Skill Chaining Protocol → Chained-invocation arg encoding — the legacy token `chained=true`, or a JSON `args` object whose `chained` key is `true` (Step 1 → gate N/A, mode pre-supplied); a Step-2 unique-match statement; or the Step-3 AUQ block. Both encodings resolve to the same `chain-skip` path: a conformant chained invocation must reach the N/A branch under either form, never the G11-05 join. | Resolution path ∈ {chain-skip, heuristic-unique, auq-fallback} captured; chain-skip → gate does **not** fire (mode pre-supplied from the Handoff Manifest, no ambiguity decision occurred). |

### Phase 2 — Content (LLM-graded; judgment, not regex)

| ID | Check | Method | Pass criterion |
|---|---|---|---|
| G11-04 | **Was an AUQ trace REQUIRED? (the load-bearing judgment — the required-but-absent FAIL lives here).** Re-derive whether the input request resolved to a **unique** mode under the skill's own trigger-match table, or was **ambiguous** across ≥2 modes (or no-match). | LLM grader reads the originating user request + the skill's `## Mode Selection` trigger-match table (Step 2) and renders `unique_match` vs `ambiguous`. This is precisely the call a regex cannot make — the same reason G8-01 is Phase 2 (an absent trace has no field to grep, and unique-vs-ambiguous is semantic). | `required = (resolution == ambiguous)`. |
| G11-05 | **Conditional-consistency verdict (Phase 1 × Phase 2 join).** Cross the deterministic `trace_present` (G11-02) against the graded `required` (G11-04). | Truth-table adjudication (below). | **PASS** iff `trace_present == required`. |
| G11-06 | **Trace-appropriateness (guards the present-but-unnecessary Phase-1 false-positive).** When a trace is present, confirm it is a *mode-selection* AUQ (routing among the skill's modes) and not an unrelated in-mode AUQ (a downstream clarification the mode itself makes). | LLM grader inspects the AUQ's `questionText`/`options` against the skill's Step-3 option list. | A present trace that is NOT the mode-selection AUQ is treated as `trace_present = false` for the G11-05 join (an in-mode question must not mask a missing mode-selection question). |

### The G11-05 truth table (the algorithm's heart)

| `required` (G11-04) | `trace_present` (G11-02, adjusted by G11-06) | Verdict | Finding |
|---|---|---|---|
| ambiguous (true) | present (true) | **PASS** | — (conforming: ambiguity correctly triggered AUQ) |
| ambiguous (true) | absent (false) | **FAIL** | *"Ambiguous input `<quote>` resolved to a mode WITHOUT an AUQ trace at `<transcript loc>`; the trigger-heuristic could not have uniquely matched (maps to modes {X, Y}) — a mode was silently chosen. Verify the `## Mode Selection` Step-3 fallback fires."* **(This is the required-but-absent case — a Phase-2 judgment, per the determinism-boundary note above.)** |
| unique (false) | present (true) | **FAIL** | *"Unique-match input `<quote>` (maps only to Mode X per the trigger table) fired an AUQ trace at `<loc>` — an unnecessary question; the heuristic should have auto-routed. Over-asking degrades the ask-when-ambiguous contract."* |
| unique (false) | absent (false) | **PASS** | — (conforming: unique match correctly auto-routed, no AUQ) |

### Verdict (binary — no CONDITIONAL, parallel to G9/G10)

- All Phase 1 PASS + G11-05 join consistent (`trace_present == required`) → **PASS**.
- All Phase 1 PASS + G11-05 mismatch → **FAIL**, with the specific transcript-loc + the
  maps-to-modes derivation cited (per the truth table).
- Any Phase 1 structural FAIL (e.g., G11-01 cannot resolve skill identity) → **FAIL**, with the
  specific non-resolution cited.
- Gate **does not fire** (N/A) when the skill is not on the roster, or the resolution path is
  chain-skip (mode pre-supplied), or there is no mode-resolution surface at all.

**No CONDITIONAL PASS for G11.** Unlike G7/G8 — which degrade gracefully on a content-quality axis
(block-quality / mitigation-actionability that can be *partly* met) — G11's conditional-consistency
verdict is binary: a trace either was or was not required, and it either is or is not present. There
is no partial-credit axis. This matches G9 (RACI) and G10 (filename-conformance), the platform's
other binary per-output gates. The verdict vocabulary is the skill's existing PASS / FAIL — **no
PARTIAL** (the skill's Operating principle and its `PARTIAL verdict — PROC` failure mode forbid it).

---

## 2. Regex derivation (G11-02) — `AUQ_TRACE_RE`, a tool-invocation match

G11-02 detects an **AUQ tool-call**, not a prose mention. The distinction is load-bearing: every
ask-when-ambiguous SKILL.md *documents* `AskUserQuestion` in its `## Mode Selection` Step 3, so a
naive `grep AskUserQuestion` matches the documentation of the fallback, not its *invocation*. A
transcript that only *describes* the fallback (without firing it) must read as `trace_present =
false`.

**Canonical detection regex** (identifier `AUQ_TRACE_RE`, screaming-snake per the reference-doc
convention for named regexes):

```
(?i)(invoke[^>]*name="AskUserQuestion"|"name"\s*:\s*"AskUserQuestion"|(^|\s)AskUserQuestion\s*\()
```

It matches three tool-invocation forms and **excludes** bare prose:
- `invoke … name="AskUserQuestion"` — the function-invoke form in a tool-call block.
- `"name": "AskUserQuestion"` — a rendered `tool_use` JSON block.
- `AskUserQuestion(` at a line-start or after whitespace — the call-token form (the trailing `(`
  is what distinguishes a *call* from a bare noun; a SKILL.md sentence "call the `AskUserQuestion`
  tool" has no immediately-following `(` and is correctly not matched).

The exclusion is deliberate and is the direct analogue of G8-03 deriving its regex from the
OLD-value string rather than matching any number anywhere: the check is scoped to the *invocation*
signature, not the *string*, so a documentation mention does not produce a false `trace_present`.

---

## 3. The roster read contract — read live from OPERATIONS.md, never hardcoded

G11's regression set — the ask-when-ambiguous-tier skills it fires on — is **read live from
`../../governance/OPERATIONS.md` § Mode Selection Protocol** (the three-tier classification table).
It is **not** enumerated in this file or in `SKILL.md`.

| Property | Rule |
|---|---|
| **Single source of truth** | The ask-when-ambiguous roster lives in OPERATIONS.md § Mode Selection Protocol. G11 reads that table at audit time and resolves the reviewed skill's tier from it. No copy is maintained here. |
| **Why not hardcode** | A copied roster silently rots when the tier reclassifies (a skill added to or removed from ask-when-ambiguous via a governed change). A hardcoded list would pass its own regression while diverging from the live tier — the exact stale-list failure the auditor exists to catch, reproduced in the auditor itself. This is codified as a Domain-Specific Failure Mode (INPUT category) in `SKILL.md`. |
| **Parameterization seam** | This is the K1↔K2 parameterization seam: the *rule* (fire on ask-when-ambiguous-tier skills) is durable K1 content and lives in the gate spec; the *membership* (which skills) is the changeable value and lives in OPERATIONS.md. G11 references the source, it does not embed the value (per the platform Parameterize-over-hardcode discipline). |
| **Tier boundary** | G11 fires **only** on the ask-when-ambiguous tier. It does **not** fire on never-ask-tier outputs (no `## Mode Selection` surface at all) or on always-ask-tier outputs (unconditional-fire — see § 4, a separate future gate). |

At the time of authoring, OPERATIONS.md § Mode Selection Protocol classifies the ask-when-ambiguous
tier as an 8-member set; that count and membership are **whatever the live table says at audit
time**, resolved by reading it — this doc deliberately does not restate the names, so it cannot
drift from the source.

---

## 4. Scope boundary — the Always-ask unconditional gate is explicitly deferred

G11 covers the **harder** conditional case: the ask-when-ambiguous tier, where a trace is required
*only when the input was ambiguous*. It deliberately does **not** cover the **Always-ask** tier
(the tier whose skills invoke AUQ *unconditionally* on every direct invocation, reserved for
destructive/production-critical asymmetry).

An Always-ask AUQ-presence check would be a **simpler, separate gate** — its rule is unconditional
("a trace must be present on every non-chained invocation"), so it has no Phase-2 required-vs-not
adjudication. That gate is a **named residual, out of scope for this release.** OPERATIONS.md §
Mode Selection Protocol Enforcement pre-registers it: "a post-hoc pmo-qa-auditor gate check (Layer 3
in the layered forcing-function pattern) is deferred; activate via a new GitHub Issue if drift is
observed across the 3 always-ask skills." G11 is the activation of the *ask-when-ambiguous* half of
that Layer-3 idea; the *always-ask* half remains its own future card, filed if drift is observed
across the always-ask tier.

---

## 5. Activation trigger (documented per the AC)

G11 activates for two documented reasons:

1. **Drift observed in the ask-when-ambiguous manual-observation regime.** OPERATIONS.md §
   Mode Selection Protocol Enforcement names a deferred "Layer 3" pmo-qa-auditor gate check to be
   activated "if drift is observed." G11 is that activation, extended from the Always-ask trio to
   the ask-when-ambiguous tier — the larger, harder surface where manual observation does not scale.
2. **Tier size exceeds the manual-observation ceiling.** The ask-when-ambiguous tier is materially
   larger than the always-ask trio; hand-watching every ask-when-ambiguous skill's mode-resolution
   behavior across releases does not scale, which is the second documented trigger for an automated
   gate.

---

## 6. Composability — where G11 sits among the Mode-Selection forcing functions

G11 is the **audit-time detection** layer for the ask-when-ambiguous mode-resolution contract. The
prevention layers are authoring/structural:

| Layer | Surface | When it fires | What it covers | What it CANNOT see |
|---|---|---|---|---|
| **Structural placement** | `## Mode Selection` as the first operational subsection of every multi-mode SKILL.md (OPERATIONS.md § Mode Selection Protocol Enforcement) | Authoring / read time | A reader meets the mode-resolution instruction before any mode content — it cannot be bypassed without skipping half the file | Whether a *specific transcript* actually fired AUQ when its input was ambiguous |
| **Guardrail reminder** | Individual skill-body guardrail text | Read time | Secondary reminder of the fallback discipline | Same — a static reminder, not a per-transcript detector |
| **G11 (this gate)** | `pmo-qa-auditor` Mode A | **QA-time, on an ask-when-ambiguous-tier transcript** | **Re-derives whether the input was ambiguous and checks the AUQ trace matches** — the required-but-absent silent-mode-choice and the unnecessary-question over-ask | Anything on a transcript that does not reach Mode A (the § 0 substrate gap); the always-ask unconditional case (§ 4) |

**Boundary vs G7/G8/G9/G10:** G7 fires on a SKILL.md file (failure-mode discipline); G8 on a Stage-5
spec with a Cascade-Sweep block (cascade completeness); G9 on any ownership-asserting output (RACI);
G10 on any artifact-naming output (filename conformance); **G11 on an ask-when-ambiguous-tier
transcript (AUQ-presence).** Each is file-type/context-conditional and does not fire outside its
trigger — G11 slots as the 11th such gate with no overlap onto G1–G10's semantics.

---

### Sources

- Add a pmo-qa-auditor Layer-3 gate that verifies ask-when-ambiguous-tier skills emit an
  `AskUserQuestion` invocation when their Mode Selection should have fired one (conditional on the
  input being ambiguous), so a silent removal of the fallback is caught by a gate rather than by
  manual observation — GitHub issue **#197**.
- The downstream QA-acceptance-review consumer that supplies G11's transcript input substrate (the
  substrate-dependency section above names why G11 needs it) is tracked at GitHub issue **#219**.

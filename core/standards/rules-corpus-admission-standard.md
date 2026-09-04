---
title: Rules-Corpus Admission Standard
purpose: The normative test a document must pass to be admitted to the deployed rules set, the frontmatter contract every admitted rule carries, and the measured byte budget the set is held to — so the rules directory grows by decision rather than by default.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: authors proposing a new rule; reviewers assessing a rules-directory candidate; the rules-budget deploy check; the rules-mirror carrier; knowledge-architecture.md §3 (load-behaviour axis)
---
<!-- reference-durability: allow-link -->

# Rules-Corpus Admission Standard

## Purpose

Everything in the deployed rules set is loaded ambiently, at session start, into every
agent's context — that is what makes it a rule rather than a document. Until this
standard existed, nothing stated what qualified a document for that treatment and nothing
bounded what the set could cost. Both absences have the same consequence: any
governance-shaped document is a plausible rule, so the directory grows by default and its
per-session cost is discovered rather than chosen.

This standard closes both. §1 states the admission test, §2 the frontmatter contract every
admitted rule carries, §3 the budget, §4 what happens when a candidate would breach it.
§5 records the founding classification verdicts and §6 the measurement they were taken
against.

**Scope boundary.** This standard answers one question — *does this document belong in
the ambiently-loaded rules set?* It does **not** answer whether the content belongs in the
corpus at all (that is [`corpus-curation.md`](../disciplines/corpus-curation.md) §1's
universality and evidence-tier gates) or which knowledge tier it occupies (that is
[`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) §1). It composes
with both and restates neither. A document can be sound corpus, correctly tiered, and
still fail admission here — the correct outcome is that it lives somewhere that loads on
demand.

---

## §1 The admission test {#admission-test}

A document is admitted to the deployed rules set **if and only if A1 ∧ A2 ∧ A3**. The
conjunction is the whole test: one failure is a rejection, and a rejection is a placement
decision, never a quality judgement about the content.

Each criterion carries a **falsifier** — the concrete thing a reviewer looks for that
would prove the criterion fails. A criterion asserted without running its falsifier has
not been applied.

### A1 — Ambient-bind {#a1-ambient-bind}

The obligation must trigger on a **broad class of action** — writing a file, making a
commit, editing governance, naming a date — rather than on entering a **named activity**.

A rule that binds only inside a named activity does not need to be resident; the activity
is itself the load event.

> **Falsifier.** Name the activity whose entry would load the document. If you can name
> one, A1 **fails**. "Any session might do it" is not an activity; "running a release" is.

### A2 — Enforcement-completeness {#a2-enforcement-completeness}

No **preventive** mechanism may already block the violation.

The preventive/detective distinction is load-bearing and is the criterion most often
misapplied. A `PreToolUse` hook that refuses the action *prevents* the harm, and a
document describing that hook is **reference about** an enforced mechanism, not a rule the
agent must hold. A **detective** gate — a post-hoc `deploy.sh --check`, a CI scan, a
review step — does **not** satisfy A2's exemption: it reports after the fact, and the
agent still needs the rule in hand to act correctly the first time.

> **Falsifier.** Name the mechanism, and state whether it blocks **before** harm or
> reports **after** it. If nothing blocks before, A2 **holds** and the document stays a
> candidate. If a preventive mechanism blocks, A2 **fails**.

### A3 — Non-invocability {#a3-non-invocability}

No reliable on-demand load path may exist — a skill trigger, a pipeline stage spec, a
pointer the agent would predictably follow.

**Reliable means total, not merely present:** a load path is reliable only when its firing
condition is implied by the obligation's own trigger, so that the document loads in
**every** session where the obligation binds — a path covering only some of those sessions
leaves the remainder unbound, and that remainder is exactly what ambient residency exists
to reach.

Ambient residency is the load mechanism of last resort. Where a dependable invocation path
exists, using it is strictly cheaper: the content costs nothing in the sessions that never
need it.

> **Falsifier.** Search for the invoking surface, then test it for **coverage**. A skill
> whose description would fire, a stage spec that cites the document, a rule that points at
> it — any one of these means A3 **fails** *if it fires wherever the obligation binds*. A
> surface citing the document from inside one activity covers that activity's sessions and
> no others, so a citation count is not the test: **a pointer is not a load path.**

### Applying the test to a candidate {#applying-the-test}

Run the A1, A2 and A3 falsifiers in order, record each outcome, then read the
disposition from this table:

| Outcome | Meaning | Disposition |
|---|---|---|
| A1 ∧ A2 ∧ A3 | **RULE** | Admit, subject to §2 and §3 |
| A1 fails | Binds inside a named activity | Home it with that activity; load on entry |
| A2 fails | A preventive mechanism already blocks it | Reference *about* that mechanism |
| A3 fails | A reliable on-demand path exists | Home it behind that path |

Where more than one criterion fails, record every failure — the disposition follows from
the set, and a partially-recorded test cannot be re-audited.

---

## §2 The frontmatter contract {#frontmatter-contract}

Every admitted rule carries five **required** fields and, above the §3 per-file trigger,
exactly one of two **conditional** fields.

| Field | Requirement | Form |
|---|---|---|
| `title` | Required | Short noun phrase |
| `purpose` | Required | One sentence stating what the rule obliges |
| `type` | Required | Literal `rule` |
| `status` | Required | Lifecycle state |
| `reversibility` | Required | Tier + confidence, per the reversibility protocol |
| `paths` | **Conditional** — see below | List of glob strings |
| `unscoped_rationale` | **Conditional** — see below | One sentence, recorded reason |

**The conditional.** A rule whose size exceeds the §3 per-file trigger MUST carry
**either**:

- **`paths:`** — a list of globs scoping the rule to the files it governs, so it loads
  when the agent touches them rather than at every launch; **or**
- **`unscoped_rationale:`** — a recorded sentence stating why ambient load is genuinely
  required and path-scoping would defeat the rule.

**Why the contract is two-way rather than an absolute `paths:` mandate.** The naive form
— "over the trigger, therefore scope it" — is falsified by the first file it meets. A rule
governing branch and commit discipline must bind *before* a branch is chosen, so there is
no set of paths that could scope it without defeating it; the agent needs it in hand
before it touches anything. An unimplementable absolute would be routed around rather than
followed. The escape hatch is therefore **recorded, not silent**, mirroring the
exemption-plus-recorded-rationale pattern in
[`canonical-skill-structure.md`](canonical-skill-structure.md) §5.

The five required fields are **observed, not proposed** — the founding admitted set
carried exactly this shape at the time of §5's verdicts, so the contract ratifies practice
rather than imposing on it.

---

## §3 The budget {#budget}

| Threshold | Value | Applies to |
|---|---:|---|
| **Per-file trigger** | **25,600 B** | Each admitted rule individually |
| **Directory ceiling** | **204,800 B** | The sum over the admitted set |

**Denominated in bytes, measured at build time, never in tokens.** Bytes on disk are
verifiable with `wc -c` and carry no heuristic. A token figure is derivable only through a
bytes-per-token estimate, and gating on an `[INFERRED]` number is an anti-pattern the
platform has already named. Token equivalents MAY be reported as context and MUST NOT
gate.

**Neither number is invented.** The per-file trigger is the existing
`C6_BYTE_THRESHOLD` — 25,600 B — reused verbatim from
[`canonical-skill-structure.md`](canonical-skill-structure.md) §5, together with its
**"triggers, not size caps"** semantic. Only the *consequence* is translated to this
altitude: there, crossing the trigger REQUIRES a non-empty `references/` subtree; here, it
REQUIRES the §2 conditional field. The directory ceiling is **8 × that constant**, so the
rules budget and the skill budget share one constant and one re-baseline story rather than
standing up a second size convention at the same altitude.

**Both are triggers, not caps, in the same sense §5 of the skill standard means it.**
Crossing the per-file trigger does not forbid the file; it obliges the scoping decision.
Crossing the directory ceiling does not forbid the candidate; it obliges §4.

**The per-file trigger and the directory ceiling are both required, and neither implies
the other.** A per-file rule alone is breached by nothing while N small files accumulate
past the ceiling — the aggregate failure is the one this standard exists to bound. An
aggregate rule alone permits a single file to dominate the set unscoped.

---

## §4 Breach behavior {#breach-behavior}

When a candidate would carry the admitted set past the §3 ceiling, or would itself cross
the per-file trigger without a §2 conditional field, the following happens in order.

1. **The check FAILs**, naming the overshoot in bytes and the **top three contributors by
   size**. A breach that reports only "over budget" tells the author nothing about where
   the weight actually is.

2. **The candidate takes exactly one of three dispositions.** There is no fourth option
   and no silent admission:
   - **Path-scope it** — add `paths:` so it loads on the files it governs;
   - **Relocate it** — to `core/standards/`, `core/disciplines/`, or a skill's
     `references/`, behind an on-demand load path;
   - **Reject it** — the content does not belong in the deployed set.

3. **Raising the ceiling is a governed re-baseline, never an inline edit.** A ceiling
   quietly raised to fit the file in front of it enforces nothing. Re-baselining requires a
   tracked work item plus a dated row in §6 recording the new value, its derivation, and
   the measured position of the admitted set at the time — the same recorded-re-baseline
   discipline `canonical-skill-structure.md` §5 applies to its own thresholds.

**Rejection is a placement decision.** A document that fails §1 or breaches §3 is not
deleted and not judged defective; it is homed where it loads on demand. The founding
verdicts in §5 include two such rejections, and neither file moved.

---

## §5 Recorded classification verdicts {#verdicts}

The founding application of §1 to the eleven members of the pre-standard mirror pair set.
Each row records the three falsifier outcomes and a one-line rationale.

| # | Member | A1 | A2 | A3 | Verdict | Rationale |
|---|---|:-:|:-:|:-:|---|---|
| 1 | `core/rules/analysis-mandate.md` | ✓ | ✓ | ✓ | **RULE** | Binds every analysis output; no preventive gate stops an agent acting on its own finding. |
| 2 | `core/rules/decision-time-adherence.md` | ✓ | ✓ | ✓ | **RULE** | Fires at an arbitrary decision moment — by construction unschedulable and unlookupable. |
| 3 | `core/rules/doc-link-maintenance.md` | ✓ | ✓ | ✓ | **RULE** | The doc-link check is **detective**; the rule is what produces a correct link the first time. |
| 4 | `core/rules/git-workflow.md` | ✓ | ✓ | ✓ | **RULE** | Branch and commit discipline must be held *before* the branch is chosen. Over the §3 trigger → carries `unscoped_rationale:`, because path-scoping would defeat it. |
| 5 | `core/rules/governance-files.md` | ✓ | ✓ | ✓ | **RULE** | Already conformant — the only member carrying `paths:` before this standard. |
| 6 | `core/rules/harness-deployment.md` | ✓ | ✓ | ✓ | **RULE** | Governs runtime-tool deployment outside the repo tree; no gate covers it. |
| 7 | `core/rules/operations-bridge.md` | ✓ | ✓ | ✓ | **RULE** | The operations-boundary hook covers one direction only; layer classification is unenforced. |
| 8 | `core/rules/rename-reference-cascade.md` | ✓ | ✓ | ✓ | **RULE** | Binds any rename, move or delete; no preventive gate exists. |
| 9 | `core/rules/skill-deployment.md` | ✓ | ✓ | ✓ | **RULE** | The skill-edit hook covers direct edits only; the deployment mapping is unenforced. Over the §3 trigger → carries `paths:`. |
| 10 | `core/rules/bypass-mode-readiness.md` | ✓ | **✗** | **✗** | **REFERENCE** | Its nine hooks enforce **preventively**, so the registry documents them rather than obliging anything (A2). Hook messages cite rule IDs on demand and the per-hook fragments are the SSOT (A3). |
| 11 | `release/governance/release-process.md` | **✗** | ✓ | **✗** | **REFERENCE (procedure)** | Binds only inside a named activity — running a release (A1). The release skills and every pipeline stage shard load it on demand (A3). |

**Corroboration — the test reproduces a boundary the corpus already asserted.** Rows 1–9
are exactly the members declaring `type: rule` in their own frontmatter; rows 10 and 11 are
exactly the two members that carried no `type:` declaration at all. Two independent
derivations — the §1 falsifiers applied by hand, and the corpus's own self-declaration —
agree member for member. The admission test is a recovery of an existing boundary, given a
gate.

**Disposition of the two rejections.** Neither file is moved, renamed or edited. Both
leave the *deployed* set only: they stop being copied into the ambient rules mirror, and
they continue to live at their source paths and to be read on demand. In particular, the
relative links inside the release procedure resolve correctly from its own location — they
were only ever strained by being mirrored to a different depth.

---

## §6 Re-baseline log {#re-baseline-log}

Every change to a §3 threshold gets a row. A threshold with no row explaining its value is
a number nobody can audit.

| Date | Threshold | Value | Derivation | Admitted-set position when set |
|---|---|---:|---|---|
| 2026-09-04 | Per-file trigger | 25,600 B | `C6_BYTE_THRESHOLD`, reused verbatim from `canonical-skill-structure.md` §5 | 2 of 9 members over trigger; both carry a §2 conditional field |
| 2026-09-04 | Directory ceiling | 204,800 B | 8 × the per-file trigger | 146,869 B — **WITHIN**, 28.3 % headroom |

### Founding measurement {#founding-measurement}

Recorded per the audit-baseline discipline: a measurement is reproducible only when its
anchor is stated. **These figures are a dated snapshot, not the live value** — the live
authority is the rules-budget check, which re-measures at build time.

| Population | Files | Bytes |
|---|---:|---:|
| Prior mirror pair set | 11 | 505,303 |
| Prior directory-shaped hook-fragment set | 12 | 145,288 |
| **Prior deployed payload** | **23** | **650,591** |
| **Admitted set after §5** | **9** | **146,869** |
| Reduction | — | **503,722 B (77.4 %)** |

- **Measured on** 2026-09-04 over the delivered state — after the §5 verdicts were
  applied to both mirror holders and the §2 contract was satisfied across the admitted
  set. The prior-payload figures are the same populations measured before those
  removals landed.
- **Position against §3:** 146,869 B of 204,800 B — **WITHIN**, 57,931 B of headroom
  (28.3 %).
- **Token equivalent** ≈ 37 K, against ≈ 163 K prior — `[INFERRED]`, reported as context
  only and **never gated** (§3).

The ceiling demonstrably bites rather than ratifying the status quo: the prior payload
overshot it by **3.18×**. The headroom is sized for roughly six further median rules
before §4 fires.

**These numbers are a dated snapshot and will drift as the admitted rules are edited.**
That is expected and is not drift to be corrected here — the live authority is the
rules-budget check, which re-derives the member list from the marker-registered holder
and re-measures at build time on every run. This row records what the thresholds were
set against, not what the set currently weighs.

---

## §7 Cross-references {#cross-references}

Cited, never restated. Each surface below owns its own content; this standard consumes it.

| Surface | What it owns | Relationship |
|---|---|---|
| [`canonical-skill-structure.md`](canonical-skill-structure.md) §5 | The `25600` byte constant and the "triggers, not size caps" semantic | §3 reuses both; only the consequence is translated to this altitude |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) §3 | The K-tier placement model | §3 of that document points here for the load-behaviour axis it does not carry |
| [`corpus-curation.md`](../disciplines/corpus-curation.md) §1 | The two orthogonal corpus gates — universality and evidence tier | Composed with, not restated: those answer *is this corpus*, this answers *does it load ambiently* |
| [`gate-efficacy-standard.md`](gate-efficacy-standard.md) | What a gate's green verdict must mean | The rules-budget check declares its posture there |
| [`reversibility-protocol.md`](../specs/reversibility-protocol.md) | The reversibility tiers | The `reversibility` field in §2 draws its vocabulary from it |

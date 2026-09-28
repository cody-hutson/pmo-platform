## Output
Post your output as a comment on sub-task #7974:

## Stage 8 QA Testing — work-nature-and-axis-model
### Summary (30 seconds)
### Detail   (Part 1: the blind re-code — codes, hash, k of 9, k′ of 7, grade and owed-set agreement, disagreements, consequences; Part 2: the Acceptance Report — per-criterion verdicts with evidence, fitness assessment, lanes, acceptance_score, recommended overall verdict)
### Evidence   (carries the mandatory `Control firings:` line, probe records per Probe-Validity, your run directory in `${SCRATCH_BASE}`-relative form, and the owed event rows)
### Decisions & Recommendations
### Output for Stage 9   (what the operator needs at the GO/NO-GO gate: the per-criterion verdicts, the D5 result and its consequence for every row, the Override Record requirements surfaced, and the recommended overall verdict)
### Model Provenance   (invocation model: `opus`)
### Mode Provenance   (declared mode: `Mode H — Acceptance Review`)

The `### Evidence` section carries one MANDATORY line, rendered on every spoke output:

    Control firings: none

or, when non-empty, one row per firing — control name · rule ID · what tripped
it · action taken (reworded / different action / stopped / user-side handoff).

**Render the line every time, including on `none`.** A spoke that routed around
a control and said nothing, and a spoke that met no control at all, otherwise
emit byte-identical output; the null line is what makes the second case
distinguishable from the first. Omission is a structural defect a QA pass can
see, not a silent pass. Full rule: § Hook-Response Discipline (all spokes).

`### Decisions & Recommendations` — for each finding requiring operator judgment:
- **Finding:** What was observed
- **Spoke Recommendation:** What you recommend — and why (grounded in your deep context)
- **Severity:** Blocker / Major / Minor / Cosmetic / Informational

`### Model Provenance`:

- **Invocation model parameter:** `opus` (passed explicitly by hub per § Spoke Launch Mechanisms — Model Parameter Required-Explicit subsection)
- **Agent-definition default:** `{model-value-from-frontmatter-at-.claude/agents/<subagent_type>.md}` (per the agent definition's `model:` frontmatter field)
- **Parent-session model:** `{as-reported-by-spoke-runtime; e.g., from claude --version or session metadata}`
- **Designated-model match:** YES / NO (PASS if all three are `opus` and match the canonical default per `platform-config.toml [spoke_runtime]` (`default_spoke_model` + `chip_model`) OR an operator-declared per-stage override in the `core/config/allowlists/agents-model-overrides.txt` companion)

`### Mode Provenance`:

- **Declared mode:** `Mode H — Acceptance Review`
- **Invoked mode:** `{the mode the spoke actually executed — the SKILL.md ### Mode X section it ran, or `single-mode` for a one-mode skill, or `N/A — no skill (general-purpose persona)` when the spoke ran as a raw persona with no SKILL.md}`
- **Mode source:** `body-heading` (`### Mode X` headings) / `description-list` (the `Modes:` line in the frontmatter `description`) / `n/a-single-mode` / `n/a-no-skill` — names the convention the skill's mode-enum was read from, so the enum's provenance is auditable
- **Mode-match:** PASS / N/A / DRIFT (PASS when Declared == Invoked AND Invoked is in the skill's mode-enum; N/A when the skill is single-mode or no skill applies; DRIFT when Declared ≠ Invoked, OR Invoked is not in the enum, OR a multi-mode skill ran with `none-declared`)

**Canonical-checklist attestation:** every codified Phase step in `stage-08-qa-testing.md` § 5 ran, or is explicitly recorded N/A-with-reason, in a table (step · ran? · evidence or N/A reason).

Then return — do NOT close sub-task #7974. Post your output comment and stop; the hub closes the sub-task after consuming your output (Procedure 4).

### Return Value to Hub
Your final message (the Agent-tool return value) is routing-only — exactly these 4 lines, nothing else:

**Spoke Result — Stage 8 QA Testing — #7959**
verdict: PASS | CONDITIONAL | FAIL | BLOCKED
sub-task: #7974 (output-posted | open-blocker)
comment: <URL of your output comment (Part 1 if split)>
next: route:stage-9-plan-review | iterate:stage-7-dev-testing | iterate:stage-6-engineering | block:operator-decision-at-stage-8 | block:dependency-#<M>

(`iterate:stage-7-dev-testing` for a QA Return to Dev Testing; `iterate:stage-6-engineering` when a Tier 1 finding needs an Engineering pass; `block:operator-decision-at-stage-8` only for a Tier 2 [SCOPE CHANGE] or Tier 3 [PLAN REJECTION] finding. Route to Stage 9 whenever the remaining decisions are the operator's Phase-E and GO/NO-GO calls.)


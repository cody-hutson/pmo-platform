---
title: Date-Variable Convention — Spec Authoring + Emission-Time Anchors
purpose: The convention for parameterizing dates as variables rather than hardcoding them across load-bearing locations, so a UTC day-boundary crossing cannot create internal contradictions — governing both Stage-5 spec authoring and tool emission time (close-out ledgers, deploy logging).
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: Stage 5 Solutioning spokes; Stage 6 Engineering (date-variable resolution at execution); AC-verifier and ADR source-observation authoring; Stage 13 close-out tooling (release/tools/automated-closeout.sh); the release-corpus ledger surfaces (RELEASE_LOG / RELEASE_INDEX / RELEASE_DIGEST / CHANGELOG / RELEASE_REVERSIONS / release notes); core/deploy/deploy.sh and core/deploy/tools/generate_release_index.py
---
<!-- reference-durability: allow-link -->
# Date-Variable Convention — Spec Authoring + Emission-Time Anchors

**Origin:**  — process-protocol; class-potential observation surfaced via the file-overlap-audit Stage 13 retrospective.
**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Primary consumer:** Stage 5 Solutioning spokes (when authoring specs whose downstream artifacts carry a load-bearing date identifier).
**Secondary consumers:** Stage 6 Engineering spokes (variable resolution at first commit); `failure-mode-standard.md` (anti-pattern catalog reference); Stage 13 close-out and deploy tooling (§ *Emission-Time Anchors*).

## Scope router — two surfaces, one root cause

This standard governs **one root cause across two surfaces**. The two trigger
predicates are **disjoint**: neither surface's consumers acquire an obligation
from the other's rules. Read the row matching the work in hand.

| Surface | The question it answers | Trigger predicate | Sections |
|---|---|---|---|
| **Spec authoring** (Stage 5 → Stage 6) | A spec is about to bake a literal date into a downstream load-bearing identifier — how is it parameterized? | § *When the convention fires (trigger predicate)* | § Purpose through § Stage 5 spec rejection criteria |
| **Emission time** (close-out + deploy tooling) | A tool is about to write a date onto a durable surface — which anchor does that date carry, and in what format? | § *When the emission-time rules fire* | § Emission-Time Anchors |

The file name retains its Stage-5 origin while the standard governs both
surfaces. That mismatch is a **known, accepted residual** — the alternative was a
rename firing a corpus-wide reference sweep, or a sibling standard restating the
root-cause analysis below, which would create a second source of truth for one
analysis. Neither cost is worth a filename.

## Purpose

Stage 5 specs that hardcode dates in multiple downstream load-bearing locations
(folder paths, AC verifier criteria, ADR source-observation references) create
internal contradictions when Stage 6 execution crosses a UTC day boundary
relative to the operator-local date used at spec authoring. Engineering faces
an unresolvable choice: honor the literal `date -u` instruction (force edits
across multiple files + break AC verification) OR honor the spec's hardcoded
references (Tier 1 [ADJUST] documentation burden). A single source-of-truth
date variable eliminates the contradiction class.

**Originating evidence:** Stage 6 Engineering Pass 1
encountered exactly this drift — `date -u +%Y-%m-%d` returned `2026-05-02`;
operator-local + verbatim Stage 5 spec references all used `2026-05-01`.
Spoke chose `2026-05-01` for consistency; documented as Tier 1 [ADJUST] in
`<OPERATOR_INSTANCE_ANALYSIS_PATH>/file-overlap-audit-2026-05-01/SUMMARY.md` § 1 UTC drift note.

**The same root cause reaches a second surface.** The mechanism above — one
logical date sampled more than once, the samples straddling a UTC boundary, the
divergent values landing in load-bearing locations that then contradict each
other — is not specific to spec authoring. It recurs at **emission time**, when
close-out and deploy tooling write dates onto durable surfaces. The close-out
script sampled its date **five separate times in a single run**, so two phases of
one close-out could straddle a UTC midnight and disagree with each other; and
because a sibling checker asserted equality across two ledgers holding two
*different* anchors, the platform's own release-index verification was red by
construction rather than by drift. The remedy is the same remedy at a different
unit of work — **sample once per unit, propagate the one value** — which is why
the emission surface is governed here rather than in a sibling standard that
would restate this analysis and then drift from it. See § *Emission-Time
Anchors*.

## When the convention fires (trigger predicate)

The convention applies to a Stage 5 spec iff ALL hold:

1. Spec text contains ≥1 literal date in `YYYY-MM-DD` form (operator-local at
   authoring time).
2. The same literal date appears in ≥1 downstream load-bearing artifact:
   - File or folder path created/named by the spec (e.g.,
     `<OPERATOR_INSTANCE_ANALYSIS_PATH>/<audit-name>-YYYY-MM-DD/`)
   - Acceptance Criterion verifier identifier (e.g., `AC-15: File present at
     <OPERATOR_INSTANCE_ANALYSIS_PATH>/<audit-name>-YYYY-MM-DD/SUMMARY.md`)
   - ADR source-observation reference (e.g., ADR `source_observation:` field
     citing a date-baked path)
   - Release-plan Deviation Log entry citing a date-baked path
3. The downstream artifact does not yet exist at spec authoring time (the
   spec instructs Stage 6 to create it).

**Does NOT fire when:**

- Date appears only in narrative context ("Survey baseline: 2026-05-21",
  "Bundle created 2026-05-16") with no load-bearing downstream consumer.
- Date is in a verbatim historical snapshot referencing an artifact that
  already exists at a fixed historical date.
- Spec creates no downstream artifacts (e.g., pure prose addition to an
  existing governance file).

**Predominant trigger today:** audit-class Stage 5 specs creating
`<OPERATOR_INSTANCE_ANALYSIS_PATH>/<audit-name>-YYYY-MM-DD/` folders (24 existing audit
folders demonstrate the pattern). The trigger generalizes — applies to any
future date-baked load-bearing identifier surface.

## Variable schema

When the convention fires, the Stage 5 spec MUST use the following variable:

| Field | Value |
|---|---|
| Variable name | `${AUDIT_DATE_UTC}` |
| Format | `YYYY-MM-DD` (ISO 8601 short form) |
| Source | `date -u +%Y-%m-%d` at Stage 6 first commit |
| Scope | Resolved value propagates consistently across ALL downstream artifacts in the release (single value per release, set once at Stage 6 first commit) |

**Variable definition block in Stage 5 spec (required, top of spec):**

```markdown
### Date Variable (per `date-variable-convention.md`)

- **Variable:** `${AUDIT_DATE_UTC}`
- **Format:** `YYYY-MM-DD`
- **Source:** `date -u +%Y-%m-%d` at Stage 6 first commit
- **Propagation rule:** Engineering resolves once at first commit; substitutes
  consistently into ALL artifacts in this release's File Change Matrix.
- **Resolution moment:** Stage 6 first commit (not Stage 5 spec authoring time).
```

The variable is referenced (not resolved) throughout the Stage 5 spec body —
every path, AC verifier criterion, ADR source-obs ref uses `${AUDIT_DATE_UTC}`
in place of a literal date.

## Stage 6 propagation discipline

When Engineering spoke begins execution:

1. Read the Stage 5 spec's Date Variable block.
2. Execute `date -u +%Y-%m-%d` at the moment of the first commit; capture
   the result as the canonical resolved value (e.g., `2026-05-02`).
3. Substitute `${AUDIT_DATE_UTC}` → resolved value across ALL artifacts the
   spec instructs Stage 6 to create or modify. The substitution is mechanical
   — Engineering does not reason about which date to use.
4. Record the resolved value in the Stage 6 spoke output's `### Detail`
   section: `Resolved ${AUDIT_DATE_UTC} = <YYYY-MM-DD> at commit <short SHA>`.
5. If `date -u` returns a different date than was implied by the operator-
   local context at Stage 5 authoring, Engineering uses the UTC value as
   the canonical instantiation. No Tier 1 [ADJUST] is required — the
   contradiction class is dissolved by the convention.

## Stage 5 spec rejection criteria (load-bearing test)

A Stage 5 spec for a release where the trigger predicate holds is **incomplete**
if ANY hold:

- Date Variable block omitted from spec top.
- Variable defined but spec body contains literal `YYYY-MM-DD` strings in
  load-bearing positions (paths, AC verifiers, ADR refs) — must use
  `${AUDIT_DATE_UTC}` instead.
- Variable resolution moment unspecified or specifies a moment other than
  "Stage 6 first commit."
- Source command unspecified or specifies anything other than
  `date -u +%Y-%m-%d`.

Stage 5 spoke output that violates these is incomplete; Collective Review
flags as a structural defect; spec returns to spoke for variable hoisting.

## Emission-Time Anchors

Scope: **dates and timestamps a tool produces at run time and writes out** — as
distinct from the spec-authoring surface above. This section governs the Stage-13
close-out script, `core/deploy/deploy.sh`, the release-index generator, and the
release-corpus ledger surfaces they write. It imposes **no obligation on Stage-5
spoke authoring**; the trigger predicate above is unchanged by it.

### When the emission-time rules fire

The rules apply to a tool iff BOTH hold:

1. The tool **produces** a date or timestamp at run time (rather than reading one
   from an input it was given).
2. That value is **emitted** — written to a durable surface (a committed file, a
   ledger row, an evidence artifact, an event log) or printed to an
   operator-facing log.

**Emitted-and-persisted vs computed-and-compared — load-bearing distinction.**
A run-time date that is only *compared* — a staleness interval, an age threshold,
any "is this older than N days" arithmetic — is **not** an emission, and these
rules do not bind it. Converting a comparison-only `date.today()` to UTC shifts a
human-facing staleness window by up to a day for an operator at a non-zero
offset: a behavior change wearing a formatting fix as a disguise. The test is
**does the value reach a surface that a human or a later tool reads back?** If
yes, it is an emission. If it only feeds an inequality, it is not. A blanket
"convert every local date to UTC" sweep fails this test and must not be run.

### The anchor taxonomy

A date on a release-corpus surface is meaningless without knowing **which event
it dates**. Three anchors exist. Every date-bearing surface carries exactly one,
and declares which one in its header prose.

| Anchor | The event it dates | Canonical format | Sampling |
|---|---|---|---|
| **Merge event** | the release PR merging to `main` | `YYYY-MM-DD` | once, at the merge (Stage 12) |
| **Close-out event** | the Stage-13 close-out run | `YYYY-MM-DD` (UTC) | **once per close-out run** — see § *Sample once per unit of work* |
| **Emission instant** | the moment a tool emitted a log line or event record | ISO-8601 UTC `YYYY-MM-DDTHH:MM:SSZ`, or local time carrying its offset (`%z`) | at each emission |

The merge and close-out anchors carry **dates, not instants**: they answer "which
day did this release event fall on", and it is the declared pairing of anchor to
surface that makes the answer resolvable. An **emission instant** is a point in
time and MUST be resolvable to one — a bare local wall-clock with no recorded
offset (`date +%H:%M:%S`, `date '+%Y-%m-%d %H:%M:%S'`, Python
`datetime.date.today()`) is **prohibited on any emitted surface**, because the
value cannot be resolved to an instant after the fact by any later reader.

### Release-corpus surface → anchor map

| Surface | Anchor | Written by |
|---|---|---|
| `release/releases/RELEASE_LOG.md` — `Date` column | **merge event** | Stage 12 chore PR |
| `release/releases/RELEASE_INDEX.md` — `Date` column | **merge event**, sourced from the LOG row | close-out `append_release_index` |
| `release/releases/RELEASE_DIGEST.md` — `### vX.Y (<date>)` | **close-out event** | close-out `append_release_digest` |
| `CHANGELOG.md` — `## [vX.Y] - <date>` | **close-out event**, derived from the release-note frontmatter `date:` | close-out `append_changelog` |
| `release/releases/notes/vX.Y_RELEASE_NOTES.md` — frontmatter `date:` | **close-out event** | close-out `scaffold_release_notes` |
| `release/releases/RELEASE_REVERSIONS.md` — date cell | **close-out event** | close-out `append_reversions` |
| pipeline event log — `ts` field | **emission instant** | `release/tools/append-pipeline-event.sh` |

**Why LOG and INDEX share the merge anchor, and DIGEST/CHANGELOG do not.** LOG
and INDEX are the corpus's two primary ledgers and the only pair carrying an
automated cross-assertion: `core/deploy/tools/generate_release_index.py --verify`
(invoked by `deploy.sh` Check 23) asserts the INDEX row equals the LOG row
field-for-field. **A checker asserting equality across a pair that holds two
different anchors is red by construction, not by drift** — it reports a
difference that is the design working correctly, and in doing so it loses the
ability to report a difference that is not. Binding both ledgers to the merge
anchor is what makes that check capable of detecting real drift. The close-out
instant is not destroyed by this: DIGEST, the release note, and CHANGELOG all
carry it, each declaring so. Both facts keep a home; the check keeps its teeth.

### Sample once per unit of work

**A tool that emits one logical date on more than one surface within a single run
MUST sample it once and propagate that value.** Repeated sampling inside a run is
the spec-authoring defect at a smaller scale: two phases of one close-out can
straddle a UTC midnight and write different dates for what the pipeline itself
treats as one atomic unit of work (the Stage-13 chore PR lands every close-out
corpus write in a single commit).

| Surface | Unit of work | Mechanism |
|---|---|---|
| Stage-5 spec → Stage-6 artifacts | one release | `${AUDIT_DATE_UTC}`, resolved at Stage 6 first commit (§ *Variable schema*) |
| Stage-13 close-out | one close-out run | a run-scoped anchor captured **once** at script start, reused by every close-out-anchored write |

### Format rules

1. **Machine and event logging** → ISO-8601 UTC with the `Z` suffix
   (`date -u +%Y-%m-%dT%H:%M:%SZ`). Already the dominant repo form; conformant
   emitters need no change.
2. **Human-facing ledger rows** → `YYYY-MM-DD`, with the anchor declared in the
   surface's **header prose**. Declare the anchor in prose, **never by renaming a
   column**: a renamed column retroactively re-labels every historical row as
   claiming an anchor it was never written under, which is a grandfathering
   violation dressed as a formatting change.
3. **Operator-facing log lines and evidence artifacts** → UTC, or local time
   carrying its offset (`%z`). Never a bare local wall-clock.
4. **Comparison-only values** → unconstrained; see the emitted-vs-compared
   distinction above.

### Grandfathering — forward-only, no backfill

The anchor declarations are **forward-only**. Rows written before a surface
declared its anchor are **not rewritten**. They are an audit trail; backfilling
them would forge history by asserting an anchor the writing tool did not use.
Consumers must tolerate pre-cutover rows whose anchor is undeclared and which, on
the LOG↔INDEX pair, diverge from each other.

**The operational hazard this creates, stated so it is not discovered the hard
way.** `generate_release_index.py` run **without** `--verify` regenerates the
INDEX from the LOG and would rewrite every pre-cutover divergent row in one pass
— the remedy and the violation are the same command minus one flag. Verification
runs use `--verify`. A full regenerate is an operator-authorized action against a
reviewed diff, never a routine step.

## Cutover

This convention applies to any Stage 5 spec meeting the trigger predicate. Cutover discipline: applies to all releases going forward.

The § *Emission-Time Anchors* rules apply to every close-out and deploy emission
going forward. Ledger rows written before those rules landed are grandfathered
per § *Grandfathering* — declared forward, never backfilled.

## Cross-references

| Surface | Reference | Role |
|---|---|---|
| Stage 5 protocol | [`pipeline/stage-05-solutioning.md` § 6 Outputs](../../release/references/pipeline/stage-05-solutioning.md) | Thin cross-reference at output enumeration |
| Stage 5 spoke prompt template | [`hub-spoke-bridge.md` Procedure 3](../../release/references/how-to/hub-spoke-bridge.md) | Inject convention reference alongside R1 Evidence-Grounding block |
| Failure-mode catalog | [`failure-mode-standard.md`](../standards/failure-mode-standard.md) | Anti-pattern `utc-drift-spec-contradiction` (added by Engineering at Stage 6) |
| Stage 13 close-out protocol | [`pipeline/stage-13-close.md` § Phase B commit mechanism](../../release/references/pipeline/stage-13-close.md) | Names the anchor each Stage-13 corpus write carries |
| Close-out emitter | [`automated-closeout.sh`](../../release/tools/automated-closeout.sh) | Holds the run-scoped close-out anchor; writes INDEX / DIGEST / CHANGELOG / notes / REVERSIONS |
| LOG↔INDEX checker | [`generate_release_index.py`](../deploy/tools/generate_release_index.py) | `--verify` asserts the merge-anchor equality this standard declares (`deploy.sh` Check 23) |

## Version History

| Version | Date | Change |
|---|---|---|
| Initial | 2026-05-21 | Initial authoring —  |
| Emission-time extension | 2026-07-31 | Extended to the emission-time surface: § *Emission-Time Anchors* (three-anchor taxonomy, release-corpus surface→anchor map, sample-once-per-unit-of-work rule, emitted-vs-compared distinction, format rules, forward-only grandfathering) + § *Scope router*. Title, `purpose:`, and `consumers:` widened. The Stage-5 trigger predicate and the `${AUDIT_DATE_UTC}` variable schema are unchanged — no existing consumer acquires an obligation. |

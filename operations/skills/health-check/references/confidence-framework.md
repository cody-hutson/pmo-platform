<!-- reference-durability: allow-link -->
# Health-Check Confidence & Staleness Framework

How a health-check finding earns its two travelling labels: a **confidence** level (how-likely-wrong) and a **staleness-depth band** (how-deep). The band scale is **not invented here** — it is the platform's canonical `S0-NONE..S3-STRUCTURAL` scale defined in [`staleness-confidence-standard.md`](../../../../core/specs/staleness-confidence-standard.md) (ADR-043). This skill projects its findings onto that scale; it authors no parallel scale and no staleness-threshold doc.

## The two axes travel together

Every finding line in every section carries: `[confidence: HIGH|MEDIUM|LOW · S0|S1|S2|S3]`.

- **Confidence** = *how likely is this finding wrong?* — a function of source agreement and recency.
- **Band** = *how deep is the drift?* — a function of what kind of problem the drift is.

A finding can be HIGH-confidence and shallow (`S1`), or LOW-confidence and deep (`S3`); the two are orthogonal and both are required.

## Confidence rule (source agreement × recency)

| Confidence | Earned when | Routes to |
|---|---|---|
| **HIGH** | ≥2 sources agree (MCP + local, or two locals) AND evidence is recent | eligible for `## Auto-Actionable` |
| **MEDIUM** | a single authoritative source; OR MCP/local disagree but one is clearly more recent; OR a finding uncross-validatable because its source was unavailable (the ADR-050 cap) | `## Decisions` |
| **LOW** | inferred via a chain; OR sources conflict with no clear recency winner; OR only stale evidence | `## Decisions` or `## Unknowns` |

A single source — even an authoritative MCP system — is **MEDIUM by definition.** HIGH is reserved for corroboration; this is the guard against one stale system driving an auto-action.

## Band projection (drift depth — projected onto the canonical scale)

The projection follows `staleness-confidence-standard.md`. The band measures depth, not elapsed time:

| Band | This skill projects a finding here when… | Lands in |
|---|---|---|
| `S0-NONE` | no drift; the tracked value is current and verified against source | `## Confirmed` |
| `S1-SUPERFICIAL` | cosmetic / mechanically-reconcilable drift — a stale path token, a renamed link, a version reference; the premise still holds | usually `## Auto-Actionable` (if HIGH) or `## Decisions` |
| `S2-SUBSTANTIVE` | a value, count, date, status, or owner whose **currency is in question** — it may no longer match source and needs verification, not a token swap | `## Auto-Actionable` / `## Decisions` |
| `S3-STRUCTURAL` | a **premise-gone / structural** mismatch — the rule or assignment the artifact asserts no longer maps to current shape | `## Decisions` (operator-rendered) |

### The two depth rules this skill inherits (do not violate)

1. **S3 only via a contradiction finding, never elapsed time alone.** A 200-day-old date with a still-valid value is `S2` at most; a 3-day-old date whose milestone was deleted is `S3`. Age does not imply structural depth — a premise/path finding does (per the standard's score-projection rule).
2. **A single (binary) signal self-reports at most a mid-depth band.** A bare currency-mismatch lands on `S2`; escalation to `S3` requires a separate premise finding (the canonical source 404s, the milestone is gone, the owner-role was abolished), not a second hidden judgment inside the representation.

## Worked examples (the three v1 modes)

| Finding | Confidence | Band | Section | Why |
|---|---|---|---|---|
| Go-live date in PROJECT.md = Jira due date = Smartsheet date, all set this week | HIGH | `S0` | `## Confirmed` | three sources agree, recent |
| Carry-forward tracker says cutover Apr 2; Jira due date says Apr 9 (set yesterday) | HIGH | `S2` | `## Auto-Actionable` | two-source currency mismatch, recent, single-owner → propose the tracker update |
| PROJECT.md owner = "TBD"; no canonical source names an owner | n/a | n/a (evidence-gap) | `## Unknowns` | unverifiable owner — surface what was searched |
| Confluence on-call page names a new owner; local RAID still names the prior owner | MEDIUM | `S2` | `## Decisions` | newer source has a replacement candidate; operator decides |
| Milestone "Phase 2 UAT" referenced in carry-forward, but the milestone was deleted in Jira | HIGH | `S3` | `## Decisions` | premise gone — a contradiction finding, structural |
| Date "Wednesday April 2" but April 2 is a Thursday | HIGH | `S2` | `## Decisions` | day-of-week mismatch — currency in question, verify intended date |

## Boundary

This framework governs **representation** — the band + confidence a finding carries. It does **not** govern **response posture** (reconcile vs. annotate vs. escalate); that is owned by `reconcile-dont-annotate.md`, which consumes the band. This skill's section routing is its posture surface, but the band itself is a faithful projection onto the canonical scale, nothing more.

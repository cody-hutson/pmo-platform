<!-- reference-durability: allow-link -->
# Mode C — Drift Audit (four-surface comparison)

The read-only mode that asserts the four roadmap-state surfaces agree, reports every mismatch with the
§7.4 4-case classification, and applies the §7.9 3-dimension cohesion check. Default output is a
**read-only report**; a CHEAP mechanical auto-fix is gated behind an explicit operator flag and never
touches the ratified initiative set.

## When it fires

- **T4** — 90-day calendar cadence (framework §5.1 T4), OR
- **T2** — a pre-release checkpoint (framework §5.1 T2; a release whose scope touches the roadmap's
  `cluster:`/`initiative:` labels), OR
- operator-explicit ("audit roadmap drift", "is the roadmap in sync").

## Audit baseline (reproducibility)

Pin an explicit baseline before the comparison — a commit anchor plus a bounded recent window — and record
it alongside the findings so the audit is reproducible (audit-baseline discipline). A surface that is
transiently empty at audit time (e.g., no open `initiative:`-drift) is not a load-bearing "zero drift"
result on its own; the pinned baseline is what makes the result re-checkable.

## The four surfaces

The fixed one-directional sync chain is **issue body (source of truth) → `initiative:`/`cluster:` label →
milestone → board fields → roadmap §3 row**. Mode C asserts the surfaces downstream of the body agree with
each other and with the body:

| # | Surface | Authoritative for |
|---|---|---|
| 1 | **Issue body** | The capability (source of truth) |
| 2 | **`initiative:` / `cluster:` label** | Categorization — should match the body's capability |
| 3 | **Milestone** | Release assignment — should match the slice's release bundle |
| 4 | **Board fields** (Initiative / Horizon / Value / Effort, token-resolved) | Pipeline/roadmap state — should match label + slice |
| 5 | **Roadmap §3 row** | A *projection* — should equal projection(upstream) |

Board fields are read via the **token-resolved ids** per
[`board-reference-contract.md`](board-reference-contract.md) — never a literal id. (Resolving the four
surfaces involves four state anchors; resolve them in sequence to avoid colliding parallel API calls
against the same board.)

## The comparison

For each issue in the audited scope, assert:
- label (2) matches the body-derived capability (1);
- milestone (3) matches the slice's release bundle;
- board fields (4) match label (2) + slice;
- roadmap §3 row (5) **equals** the projection of the upstream surfaces (a hand-edited §3 row that diverges
  is a drift finding — §3 must never be an independent source).

## Classify each mismatch (§7.4 4-case diagnostic)

Route every mismatch through the framework §7.4 gap diagnostic and name an actionable next step:

| Case | Classification | Action |
|---|---|---|
| (a) | Work doesn't exist (no Issue, no Milestone) | File an intake ticket → link the gap |
| (b) | Work exists but isn't mapped to the roadmap | Fix mapping (milestone back-reference + §3 row) |
| (c) | Work exists unbundled (Issue without Milestone) | Bundle into the appropriate Milestone (Stage 3 re-bundle) |
| (d) | Work already shipped | Fix mapping (mark §3 "Shipped" + capture contribution-to-outcome) |

Each finding carries the case letter + the named action verb + the cross-link to the tracking Issue.

## Cohesion check (§7.9 3 dimensions)

Apply the framework §7.9 cohesion check to the §3 Now/Next/Later:

| # | Dimension | Question |
|---|---|---|
| 1 | **Requirements completeness** | Does §3 span the full causal chain from §1 Capability Outcome to deliverable milestones? Any untracked links? |
| 2 | **Design coherence** | Do the §3 milestones share consistent architectural assumptions? Any in tension with the §2 scope axioms? |
| 3 | **Seam detection** | Are cross-milestone seams documented in §3 or flagged in §3a Identified Gaps? Any implicit/undocumented? |

A cohesion check that flags **zero** issues across all three dimensions is **suspicious** (most
multi-milestone roadmaps have at least one seam) — re-examine before reporting a clean result.

## Output

- A **read-only report**: per-issue surface comparison, each mismatch with its §7.4 case + action +
  cross-link, the §7.9 cohesion findings, and the pinned audit baseline.
- **Reversibility:** each finding is **CHEAP** (a read-only observation). A proposed mechanical fix is
  CHEAP; a finding that implies re-homing work across initiatives is **MODERATE+** and is surfaced, not
  applied.
- **Auto-fix is gated:** only behind an explicit operator flag, and only for a mechanical mismatch (e.g.,
  a stale §3 row the upstream surface already corrected → regenerate the projection). Auto-fix **never**
  changes the ratified initiative set and never re-derives initiatives.
- Accumulated `initiative:`-drift (issues fitting no initiative; recurring label-vs-capability conflicts)
  is reported as a **re-baseline signal** with a count — surfacing a Mode B recommendation to the operator,
  not auto-triggering it.

## Invariants asserted by this mode

- Read-only by default; auto-fix is explicit-flag-gated and mechanical-only.
- Board reads are token-resolved (no literal id).
- §3 is asserted to equal projection(upstream); a divergent hand-edited §3 is a drift finding.
- The ratified initiative set is never touched in Mode C.
- A zero-finding cohesion check is treated as suspicious, not as a pass.

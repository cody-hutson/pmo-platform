<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-091 — Scope-segregation PreToolUse hook — destination-sensitivity content gate (payload-triggered, fail-closed)
status: Accepted
date: 2026-07-25
release: 46-cross-platform-install-experience (v3.91)
deciders: "Workspace owner (to ratify at the v3.91 Collective Review scope-lock); design resolved at #384 Stage-5 Solutioning + its A6.5 adversarial review"
tags: [architecture, security, hooks, pretooluse, scope-segregation, trackers, fail-closed, pii, reversibility]
source_observations:
  - "#384 Stage-5 Solutioning (#3877): the operator tracks work across heterogeneous destinations that must stay segregated (public GitHub vs private Jira/Linear); no hook refuses content by DESTINATION sensitivity today. git-pre-commit-pii guards commits; block-gh-path-leak guards gh bodies (public-assumed, path-only, Bash-only). A filing-time gate is the open surface."
  - "#3877 A6.5 adversarial review: the original design failed OPEN on five composing choices — a private-scope project with a needle-clean body and an unset work_tracker files to public GitHub, green, at ship. The four counter-designs (CD-1..CD-4) close the stacked fail-open in-band with no re-quota and no fission change."
  - "#383 durable round-trip (setup-workspace.sh write_operator_toml): operator-added sections are preserved by UNIQUE section name; a [[trackers]] array-of-tables collapses to one corrupt block on re-emit, but [trackers.<id>] named subtables round-trip unchanged (traced, and covered by the INT-1 durability test)."
---

# ADR-091 — Scope-segregation PreToolUse hook: destination-sensitivity content gate

## Status

**Accepted.** Authored at #384 Stage 6 per the Stage-6 ADR-authoring precedent
(ADR-031 / ADR-007 / ADR-028). Ratified by the workspace owner at the v3.91
Collective Review scope-lock (Stage 9 GO, 2026-07-25). It references issues as bare `#N` with the file-level
`allow-issue-ref` marker above.

## Context

Operators file work items to heterogeneous trackers that must not cross-contaminate:
a public GitHub repo for one stream, a private Jira/Linear for another. The platform
gains a multi-destination tracker config (`operator.toml` `[trackers.<id>]` named
subtables, each `{ id, platform, identifier, scope }`) and needs a **filing-time
guardrail** that refuses private/PII-marked content bound for a `scope: public`
destination.

Two prior PII surfaces exist and neither covers this: `git-pre-commit-pii.sh` guards
git commits (not tracker filings), and `block-gh-path-leak.sh` guards `gh` issue/PR
bodies but is path-needle-only, `gh`-Bash-only, and public-assumed (it does not read
a declared destination scope, and it fails OPEN on an empty body). The story mandates
REUSING the existing PII detector rather than authoring a new one.

The A6.5 adversarial review found the naive design — payload-triggered content scan,
permissive default on unmapped destinations, uniform warn-mode-first — **fails open**:
five choices each default toward public exposure, and they compose. A security control
whose one job is "public and private work cannot cross-contaminate" must fail CLOSED
toward the thing it protects.

## Decision

Ship **`core/hooks/block-scope-segregation.sh`** — a PreToolUse hook, **payload-triggered**
(per the ADR-031 precedent, NOT session-detection), registered on the `Bash` and
`mcp__.*` matchers (LAST per matcher, so the safety barriers evaluate first). It fires
on tracker-FILING verbs only (early-exit otherwise), resolves the filing destination →
its `scope` from `operator.toml` `[trackers.<id>]`, and refuses private/PII-marked
content bound for a `scope: public` destination. It **reuses** the existing PII
substrate (the shared `path-leak-patterns.sh` primitive + the two generic patterns
from `git-pre-commit-pii.sh` + the gitignored localized-context needle file) — no new
detector.

The enforcement posture is **fail-closed**, per the A6.5 amendments (each is
load-bearing; the original design failed open on all four):

1. **Schema — Option B named subtables.** `[trackers.<id>]` (NOT `[[trackers]]`
   array-of-tables). Each subtable is a unique section name that round-trips unchanged
   through the shipped `#383` `write_operator_toml` preservation path; an array-of-tables
   collapses to one corrupt block on the first re-emit. `[adapters].ticketing` and
   `[platform].work_board` are retained as deprecated back-compat aliases; with NO
   `[trackers.*]` declared, filing resolves to a single `default` destination = today's
   single-GitHub behavior with zero operator action.

2. **CD-1 — fail-closed routing default.** The filing-resolution order is
   explicit-selection > active-project `work_tracker` > `default`. Once ANY
   `[trackers.*]` is declared, a private-scope project with an UNSET `work_tracker`
   MUST NOT fall through to a public destination — resolution fails closed (blocks /
   requires explicit selection) rather than routing private-origin work to public.
   The "no trackers configured at all" case remains permissive (legitimate single-stream
   back-compat). Primary home: the routing read path (intake-desk create path +
   `project-schema.md` `work_tracker`); the hook's contribution is a fail-closed default
   on an unmapped destination when trackers are configured.

3. **CD-2 — tiered always-block.** A high-confidence identity/private needle
   (operator home-path / phone / personal-email, or a declared coworker/org/client-project
   needle) bound for a `scope: public` destination is **always blocked regardless of
   hook mode** (mirroring `git-pre-commit-pii.sh`'s unconditional exit and
   `block-autonomy-ceiling.sh` `always_block`). Warn-mode-first applies ONLY to the
   fuzzy / destination-resolution layer (unmapped-destination and empty-extraction). A
   warn window must not be a window of irreversible public PII exposure. The allowlist
   and `CLAUDE_HOOK_BYPASS=1` remain the per-match / per-session escapes.

4. **CD-3 — fail-closed content-extraction.** On the mapped-`scope: public` branch, an
   empty / unparseable content extraction fails closed (would-block in warn, block in
   enforce) — UNLIKE `block-gh-path-leak.sh`'s fail-open-on-empty. On the MCP surface
   empty-extraction is the common case, not the edge case, so treating it as clean would
   be a systematic false-negative.

5. **CD-4 — needle-coverage extension + stated boundary.** The operator-fillable needle
   surface is extended beyond operator-identity to private-PROJECT content (a
   client / project-code / internal-system needle class in the gitignored
   localized-context needle file). The **coverage boundary is stated, not implied by a
   green test:** public-filing is guarded for operator-identity PII unconditionally, and
   for private-project content only to the extent the operator has declared those
   needles. Undeclared private-project prose is caught by the CD-1 routing fail-closed
   (never route a private-scope project to public), not by content-scan; content-scan is
   defense-in-depth.

**Mode + escapes.** The hook ships **warn-mode-initial** via its OWN
`.scope-segregation-mode` file (NOT the shared `.mode`), so its shakedown→enforce
lifecycle is independent (highest false-positive risk); the enforce flip for the fuzzy
layer is a separate operator gate. Three disable paths: `.scope-segregation-mode=off`;
the new bypass-mode allowlist `scope-segregation-allowlist.txt` (registered in
`allowlist-add.sh` + the bypass-mode registry — the allowlist-count cascade); and
`CLAUDE_HOOK_BYPASS=1` (anti-injection-protected by BLOCK-DESTRUCTIVE-023).

## Alternatives Considered

- **(A) Extend `block-gh-path-leak.sh`** — rejected: it is `gh`-Bash-only, path-needle-only,
  and public-assumed (reads no declared destination scope, no MCP coverage).
- **(B) `[[trackers]]` array-of-tables schema** — rejected: it does not round-trip through
  the shipped `#383` preservation path (collapses on re-emit) and would force round-trip
  surgery in a shared file, creating new contention.
- **(C) Session-detection trigger** — rejected per the ADR-031 precedent (hooks do not read
  session-context fields; the payload is the universal signal).
- **(D) Uniform enforce-by-default** — rejected per the bypass-mode-readiness warn-first
  convention for the fuzzy layer; but the crown-jewel identity class is always-block (CD-2),
  so warn-first does not weaken the control below its cited precedents.
- **(E) Permissive-default on all unmapped destinations** (the original design) — rejected by
  A6.5 CD-1: it is the fail-open bug for a configured multi-destination install.

## Consequences

- **Never-PII-to-public is enforced at filing time**, across both the Bash-`gh` and MCP
  filer surfaces, by DESTINATION scope — a capability neither prior PII surface provided.
- **The hook fires on every Bash/MCP call** — the filing-verb early-exit is load-bearing;
  performance is bounded by the same early-exit pattern block-autonomy-ceiling uses.
- **Fail-closed is real but bounded.** The always-block identity tier is mode-independent;
  the routing/extraction fuzzy layer is warn-mode-initial and hard-enforces only after the
  operator flips `.scope-segregation-mode`. Documentation never claims unqualified
  hard-enforcement.
- **A residual is stated, not hidden (CD-4).** Content-scan covers operator-identity PII
  unconditionally and private-project content only where the operator has declared needles;
  the CD-1 routing fail-closed is the primary segregation gate. The higher-altitude
  refuse-by-ORIGIN-scope model (content-scan as pure defense-in-depth) is surfaced for a
  future AC revision.
- **A fast-follow is owed.** The detector reuse ships as inline-reuse (the hook sources the
  shared path-leak primitive + the localized-needle resolver and inlines the two generic
  regexes with `git-pre-commit-pii.sh` cited as the sibling home). Extracting a single
  shared `pii-needle-patterns.sh` that both hooks source is deferred to avoid regressing the
  shipped commit-guard this release.
- **Missing-jq / missing-primitive posture** matches the suite: mode-aware fail-closed
  (enforce blocks; warn/off degrade). On a brew-only host during the warn shakedown the
  scan can degrade — the same accepted residual as block-autonomy-ceiling / block-gh-path-leak.

## Reversibility

**MODERATE / Confidence HIGH.** Additive hook + additive config schema + deprecated-alias
back-compat. Disable via `.scope-segregation-mode=off`, the allowlist, or
`CLAUDE_HOOK_BYPASS=1`; the enforce flip for the fuzzy layer is a separate operator gate.
Removing the capability is a hook deregistration + schema revert with no data migration.

## Related ADRs

- ADR-031 — autonomy-ceiling unified payload-triggered hook (the payload-trigger +
  own-mode-file + warn-initial precedent this ADR follows).
- #384 — Support multi-destination work-tracker config with a scope-segregation guardrail
  (the parent story).
- #383 — operator.toml durable round-trip (the preservation path Option B relies on).

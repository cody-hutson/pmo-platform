<!-- reference-durability: allow-link -->
---
title: ADR-204 — Egress allowlist rows declare their match domain; a leading glob never grants a gh-api write
status: Accepted — ratified at the egress-hook-batch Stage-5 Collective Review scope-lock
date: 2026-09-24
release: egress-hook-batch
deciders: "Workspace owner (operator) — decision rendered at the release's Stage-5 Collective Review scope-lock, with the independent adversarial review's refinements folded in; design by the Stage 5 Solutioning spoke (eight-candidate design exploration, narrowed to two before scoring); authored by the Stage 6 Engineering spoke"
tags: [egress, block-egress-007, block-egress-004, allowlist, match-domain, scope-directive, fail-closed, revert-safety, trust-boundary, composition-surface]
source_observations:
  - "One allowlist file serves two disjoint match domains — the host of a curl upload and the path of a gh api write — and the matcher applied every row to both. A bash case glob's * crosses /, so the host wildcard *.github.com matched any gh api path ending in .github.com: the host-pattern-over-path conflation."
  - "A query-string suffix makes any write endpoint end in host-shaped text: repos/<any>/<any>/issues?x=a.github.com was allowlisted by the host row, so the exposure covered issue creation on any public repository, which needs no write access."
  - "The reverse held as well: the slashless path row graphql was consulted as a host, so it allowlisted a curl upload to a host of that name. Measured at the release baseline against the shipped hook: every managed host row was granted in both domains, and so was the graphql row."
  - "The pre-change matcher skips every line whose first character is #, so a directive written as a comment line is invisible to it; measured with a grammar replica at Stage 5, the pre-change matcher returns identical verdicts over the new-format file and over the pre-change file."
  - "Only a glob can make a row match more than one exact string, and a host wildcard reaches a path only by absorbing its whole front: every managed gh-api path row had a literal first segment, and the one managed row with a glob in its first segment was the host wildcard."
  - "The deployed operator-additions region on the authoring instance held no rows, so no deployed grant changed scope; other installations can hold any rows, which is why a row with no directive keeps its pre-change matching."
  - "The independent adversarial review found the draft's claim that the guard closes the class for every row overstated: the leading-glob guard runs only at the gh-api path site, so an undeclared slashless row stays a host candidate. The claim was corrected and the residual named at the scope-lock."
---

# ADR-204 — Egress allowlist rows declare their match domain; a leading glob never grants a gh-api write

## Status

**Accepted.** Ratified by the operator at the egress-hook-batch Stage-5 Collective Review scope-lock, which locked the design together with four refinements from the independent adversarial review; authored at Stage 6 Engineering after that lock.

**Numbering provenance.** Claimed as **204** against an anchor of **203** on `origin/main`, read from the repository's own ADR-numbering detector rather than computed as one past the highest number visible on any branch. The number binds at the Stage-12 claim; should the mainline claim it first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. In-release prose cites this record by its slug token, which carries no number shape and resolves at the claim.

**Authoring provenance.** The Stage-5 design named this record; the File Change Matrix ratified at the Stage-4 gate carried no path for it, so the release plan's Deviation Log records the added row with its authority.

## Context

The egress hook reads one allowlist for two rules. BLOCK-EGRESS-004 matches the host of a curl upload; BLOCK-EGRESS-007 matches the resolved path of a `gh api` write. The file's header documented which rows were hosts and which were paths, but nothing the matcher could read carried that distinction, so every row was a candidate at both sites. Because a bash `case` glob's `*` crosses `/`, a host wildcard became an unanchored suffix rule over path space: `*.github.com` allowlisted any gh api write whose path ended in `.github.com`, and a query-string suffix made every write endpoint end that way. The reverse held too: the path row `graphql`, which has no `/`, allowlisted a curl upload to a host of that name.

Three constraints shaped the fix. The operator-additions region of the deployed file lives outside git and is preserved verbatim by the update path, so no fix may rewrite operator rows, and no pull-request diff can show their fate. A revert must restore exactly the grant set that existed before the change. And the hook's publisher and the allowlist's composition writer are separate paths that can run in either order, so the fix must be safe with a new hook and an old file, and with an old hook and a new file.

## Decision

The platform adopts three rules for `core/config/allowlists/egress-allowlist.txt`, applied by `is_allowlisted` in `core/hooks/block-egress.sh`:

1. **A row declares its domain on the line directly above it.** `# egress-scope: host` or `# egress-scope: gh-api-path` binds the one row that follows; any other line in that position discards it, so a scope never carries onto a later row. A directive naming any other value makes its row match nothing. Every managed row carries a directive.
2. **A row with no directive is consulted in both domains**, which is how every row was matched before directives existed. Only the operator-additions region can hold one.
3. **At the gh-api path site, a pattern whose first path segment carries a glob character is never a candidate**, whatever its directive says.

The rules apply only where a call site names a domain — `host` at BLOCK-EGRESS-004 and `gh-api-path` at BLOCK-EGRESS-007. The ssh and WebFetch rules read their own single-domain files and pass no domain, so they are matched exactly as before. `allowlist-add.sh` gains an optional `--scope host|gh-api-path` that writes the directive and the entry as an adjacent pair; when the entry already exists as a bare row, `--scope` declares that row where it sits rather than adding a second one, and it edits only inside the operator-additions region, never a managed section. Without `--scope` the row is written with no directive, and the helper states how it will be matched.

The narrowed deny rides BLOCK-EGRESS-007's existing rollout classification unchanged: it enforces at the command positions the replaced matcher adjudicated, and is shadow-logged at every widening position until that rule's widening phase graduates.

## Alternatives Considered

- **A scope prefix on every row** (`host:api.github.com`). Rejected on revert safety: the pre-change matcher reads the prefix as literal glob text, so any row written in the new form stops matching after a revert, and an old hook reading a new file denies every egress write. This was the strongest losing option.
- **Directives that open a section** running to the next directive or fence. Rejected: a row added below a scoped entry silently inherits that entry's scope, so a notice about how a new row is matched would be false; preventing it needs a reset keyed to the composition writer's fence text and a terminator value.
- **One allowlist file per match domain**, as the ssh and WebFetch rules already have. Rejected: the existing file covers the capability in place, so a new composition surface — with its manifest row, its stated counts and its install coverage — cannot be justified as net-new, and operator rows moved into it would be revoked by a revert, because the prior matcher never reads that file.
- **Inferring a row's domain from its shape** (a `/` means path). Rejected: it keeps the root cause — the domain is still not declared — and cannot classify a path row with no `/`, such as `graphql`.
- **Making `*` stop crossing `/` at the path site.** Rejected: a single-segment path such as `evil.github.com` still matches, and every path row that relies on `*` spanning segments would lose its grant.
- **A structured allowlist with a shared scope-aware matcher library.** Rejected: a new shared hook library and a new file format are a structural change where a behavioural one suffices, and the composition surface's file format is fixed.
- **The leading-glob guard alone, with no declarations.** Rejected as a complete fix — a literal host row would still be a path candidate, and the `graphql` row would still admit a curl upload — and kept as rule 3.
- **For rows with no directive: host-only, neither, or declared-only after a dated graduation.** Rejected: host-only and neither revoke operator grants on upgrade with no upgrade-time signal, and the dated graduation has no enforcing deadline. Rule 3 already removes the one shape that lets a host row reach a path, so consulting undeclared rows in both domains keeps every existing grant without reopening that direction.
- **Laddering the narrowed deny through its own shadow phase.** Rejected: it would keep a known exfiltration class open to protect a false-deny population that is empty by construction — no legitimate write endpoint of an allowlisted account is matched only by a host row.

## Consequences

**Positive.** A host row can no longer grant a gh api write, and a row declared `gh-api-path` can no longer grant a curl upload. The change is monotone: every call site's candidate set is a subset of what it was, so no value is newly allowed anywhere. The host-wildcard-over-path direction is closed for every row, declared or not, because rule 3 needs no directive — which is also why the fix holds in either publish order. A revert restores the prior grant set without touching the operator region. The ssh and WebFetch rules are untouched.

**Negative.** The reverse direction is closed only for declared rows. Rule 3 runs at the gh-api path site alone, so a row with no directive and no `/` in the operator region stays consultable in both domains: a slashless glob such as `gist*` still grants a curl upload to every host it matches, and a slashless literal still matches its one exact string as a host and as a path. A directive is the only thing that confines such a row, which is why the helper's notice names `--scope` and why a `--scope` re-add declares an existing bare row in place. Every managed row carries a directive line, so the managed body is longer. An operator gh-api path row whose first segment is a glob — already contrary to the file's prefix-anchoring rule — stops matching, failing closed with the standard deny message. The spellings BLOCK-EGRESS-007 has not yet graduated — implicit POST, later invocations, new command positions — remain shadow-allowed and observable in the warn log until that rule's widening phase is advanced. And at the shipped shared mode of `warn`, the narrowing is observability rather than enforcement everywhere.

## Reversibility

CHEAP. Revert the merge, republish the hook bundle, and let the update path regenerate the allowlist's managed section. A directive is a comment line to the prior matcher, so the prior matcher reads the new-format file exactly as it read the old one, and nothing in the operator-additions region needs rewriting.

## Related ADRs

- ADR-014 — the managed section's two-hash tamper detection covers the directive lines, which are ordinary managed-body content, and is why the helper never edits a managed section.
- ADR-030 — the hook-registry fragment that documents this rule regenerates the registry index.
- ADR-078 — the security hooks' fail-closed posture for input a control cannot interpret, which a mistyped directive follows by matching nothing.
- ADR-094 — extend-before-create, under which the one-file-per-domain option was rejected.
- ADR-187 — command-position canonicalization; BLOCK-EGRESS-007 keeps its own token-level reader, unaffected here.
- ADR-192 — the same matcher property decided for the script-execution allowlist: a leading glob absorbs an arbitrary prefix, so it is a widening.
- ADR-203 — the hook publisher's refresh discriminator, which governs how this change reaches a deployed hook tier.

## References

- #5592 — the host-pattern-over-path conflation defect this record resolves, with its five acceptance criteria.
- #6195 — the graduation of BLOCK-EGRESS-007's widening phase, which owns the shadow-allowed residual.

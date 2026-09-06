<!-- reference-durability: allow-link -->
---
title: "ADR-192 — Four allowlist invocation forms remain canonical; the suffix glob is a widening, not a completion"
status: Accepted
date: 2026-09-05
release: release-tools-invocable-gates-enforced
deciders: "Stage 5 Solutioning spoke (three-option design exploration, narrowed before scoring) + Stage 6 Engineering spoke (build, matcher parity assertion, corpus re-derivation)"
tags: [script-execution-allowlist, block-destructive-022, invocation-forms, script-laundering, matcher-semantics, per-tool-exception, arm-f, ADR-094]
source_observations:
  - "Four consecutive releases left the question 'is the canonical form set four or five?' open, and each answered it locally. The allowlist's own convention block says four; one tool carries five; six telemetry producers carry a different fifth form; two blocks deliberately carry two."
  - "Measured against the hook's own matcher at authoring (2026-09-05): the pattern `*/release/tools/t.sh` matches the absolute install path, the worktree path, the dot-relative path AND `/tmp/attacker/release/tools/t.sh`, but NOT the bare-relative `release/tools/t.sh`."
  - "So the fifth form is not a fifth coverage increment beside the first three. It SUBSUMES forms 1-3 with the anchor removed, misses form 4, and admits an arbitrary path prefix."
  - "At authoring the allowlist held 313 non-comment rows over 77 basenames, 61 of them carrying exactly four forms. Canonicalizing the fifth form would have applied the prefix admission to every registered tool at once."
  - "Two live surfaces independently assert four by name: the deploy refresh-surfaces suite reports 'all four invocation forms present (absolute, worktree-glob, dot-relative, bare-relative)', and the solutioning output template grades 'fewer than all four invocation forms' as a partial registration."
  - "The earlier five-form reading was adopted on downstream-clone reachability — a real need for a tool at an unpredictable checkout path. That decision's record weighs reachability and does not weigh prefix admission, so the two readings are about different properties rather than in direct conflict."
  - "A tool holding a row can still be unreachable: one telemetry producer carried a cwd-relative row that cannot match the `bash release/tools/<tool>` spelling its own stage spec prescribes. A row count is therefore an unfaithful proxy for reachability."
---

# ADR-192 — Four allowlist invocation forms remain canonical; the suffix glob is a widening, not a completion

## Status

**Accepted.** Authored at Engineering for the `release-tools-invocable-gates-enforced` release, alongside the convention-block amendment and the reachability arm it governs.

**Numbering provenance — `191 → 192`.** Held **ADR-191** branch-local; renumbered to **ADR-192** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 191. In-release citations that read "ADR-191" denote this record.

## Context

`core/config/allowlists/script-execution-allowlist.txt` is read by a PreToolUse hook to adjudicate subprocess script execution. It exists to close a script-laundering path — write a script, then invoke it through an interpreter — so what it admits is a security surface and not merely a convenience roster.

The file's per-tool form convention states that a registered tool is listed in **four** forms: the absolute install form, the worktree-glob form, the dot-relative form, and the bare-relative form. The corpus did not agree with the block. Some tools carried a fifth `*/…` suffix glob; a set of telemetry producers carried a different fifth form, the cwd-relative `./<tool>`; two blocks carried only two forms and said in terms that the shortfall was deliberate. The convention block was **silent about all of it**, and that silence is what let "four or five?" stay open across four releases, each answering it locally and none of them wrong on its own terms.

The question came due because a release had to register tools that a pipeline spec mandates but no agent could run, and "register it correctly" has no answer until the form set has one.

## Decision

**Four forms remain canonical.** The fifth (`*/<path>/<tool>`, a generic suffix glob) and the sixth (`./<tool>`, cwd-relative) are **per-tool exceptions, each carrying a written reason at its own block**. Neither may be applied as a blanket convention, and a tool carrying an exception form still carries the canonical four unless a comment at its block says otherwise and says why.

The deciding evidence is a measured property of the matcher, not a count of precedents. The hook matches with `case "$path" in $pattern)`, and `*` in a bash `case` pattern crosses `/`. Executed against the matcher itself:

```
PATTERN: */release/tools/t.sh
   MATCH   /Users/x/Claude/pmo-platform/release/tools/t.sh
   MATCH   /Users/x/Claude/pmo-platform/.claude/worktrees/w1/release/tools/t.sh
   MATCH   ./release/tools/t.sh
   no      release/tools/t.sh
   MATCH   /tmp/attacker/release/tools/t.sh
```

So the suffix glob **subsumes** the first three forms rather than adding a fourth increment beside them, **does not** cover the bare-relative form — which is why the four-form set is not redundant under it — and **additionally admits an arbitrary path prefix**, including a directory an attacker controls. Canonicalizing it would apply that admission to every registered tool at once, widening the exact surface the file exists to narrow.

**This scopes the earlier five-form reading rather than overturning it.** That reading was adopted for a genuine need: a tool that must run from a checkout at a path the file cannot predict — a downstream clone, a differently-named directory. That need is real and the form remains correct for it. What the earlier record did not weigh is prefix admission, because the matcher had not been probed. Naming the qualifying bar preserves the reachability case and removes the blanket.

## Decision kernel (version-agnostic)

A pattern that removes an anchor is a **widening of the admitted set**, never a completion of an enumeration — regardless of how many tools already carry it. Where a looser pattern subsumes stricter siblings, adopting it corpus-wide is a security decision about every member at once, and it is justified per tool by a stated reachability need or not at all.

## Alternatives Considered

| Option | What it canonicalizes | Effect on the registered-tool population | Verdict |
|---|---|---|---|
| **A — raise canonical to five** (adopt the suffix glob everywhere) | forms 1–5 | **Widens.** Every registered tool gains arbitrary-prefix admission simultaneously. It would also contradict the two live surfaces that assert four by name. | **Rejected** |
| **B — reduce canonical to two** (the suffix glob plus the bare-relative form, which together are strictly more permissive than the current four) | forms 4–5 | Same widening as A, and it additionally deletes the anchored forms that bound it. Cheapest to write, worst to own. | **Rejected** |
| **C — keep four canonical; the fifth and sixth are per-tool exceptions each carrying a written reason** | forms 1–4 baseline | **Neutral.** The anchored forms stay the default; the loosening stays opt-in and justified where it is used. | **Adopted** |

A fourth option — leaving the convention block silent and continuing to answer per release — is what produced the ambiguity and is rejected by the existence of this record.

## Consequences

The convention block now names the two exception forms and each one's qualifying bar, so a later author reaching for the suffix glob meets the reason before the pattern. The two deliberately-short blocks are protected by the same amendment: it states that a block may sit below four when a comment says why, which is what those blocks already do.

A cost worth naming: an exception form now requires a written reason at its block, so registering a tool that genuinely needs one is slightly more work than copying a neighbouring row. That is the intended direction — the fifth form's cost was previously invisible at the point of use, which is precisely how it spread.

This decision also settles the question for a companion mechanism in the same release: an arm asserting that the invocation a pipeline spec prescribes is admitted by the allowlist can only grade "registered correctly" once "correctly" has a definition. It asserts the matcher rather than a row count — a count is an unfaithful proxy, as a tool holding a row while remaining unreachable from its own spec's spelling demonstrates.

## Reversibility

**MODERATE / Confidence HIGH.** Reversing to a five-form canon is a text change to one convention block plus whatever rows an author then adds. What is not cheap to reverse is the corpus state a blanket adoption would create: rows added across the registered-tool population would each have to be found and removed, and any invocation that began relying on prefix admission in the interim would break on the way back. The asymmetry is the reason for deciding it deliberately now rather than letting it settle by accretion.

## Related ADRs

- `ADR-094` — the extend-before-create discipline, under which the reachability assertion this decision enables was hosted on an existing engine rather than a new check.
- `ADR-181` — ADR citations bind at the claim, not at authorship; this record is cited by slug in branch-authored prose and its number binds at the Stage-12 claim.

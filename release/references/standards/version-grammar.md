<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Canonical Version Grammar — Validation, Parsing, and Total Order
purpose: Defines the platform's single canonical version grammar (vMAJOR.MINOR and vMAJOR.MINOR.PATCH), the integer-triple total order over versions, the freeness contract that order makes decidable, and the consumer rule that every freeness/comparison call site sources the one SSOT shell library rather than re-encoding the grammar. This is the grammar all version-freeness and version-comparison work sources; it is the contract, the executable claim/freeness gates that consume it are separate slices.
type: standard
reversibility: MODERATE / Confidence HIGH — a tightened grammar is loosenable and the SSOT library reverts cleanly (git revert removes the new file); no tag is mutated. The total order is a pure definition with no runtime surface of its own.
implemented_by: release/tools/version-grammar.sh
composes_with: repo-host-adapter-versioning (the host adapter exposes anchor/claimed_set/atomic_claim/lineage; this grammar is the host-agnostic string contract those operations exchange and order)
---

# Canonical Version Grammar — Validation, Parsing, and Total Order

> Reversibility: MODERATE / Confidence: HIGH. This grammar is the single source of truth for what a valid version string is and how two versions order. It is implemented once in the SSOT shell library `release/tools/version-grammar.sh`; every freeness check and version comparison sources that library and calls its functions. Re-encoding the grammar inline at a call site is a divergence defect — the exact failure this grammar exists to eliminate.

## 1. Why one canonical grammar

Releases ship as two-component versions (`v2.12`), three-component hotfix versions (`v2.06.1`), and — historically, in a permissive validator — were nominally allowed to take suffix forms (`v2.07b`, `v2.04b-1`). A freeness or comparison check written only for the two-component `vX.Y` shape cannot see a third component and therefore cannot decide whether a hotfix and the next minor collide. Worse, when each call site carries its own copy of a version regex, the copies drift independently, and a version string accepted in one place is rejected in another. Both problems have the same root: there was no canonical grammar, stated once, that every site consumes.

This document states that grammar, the total order over versions, and the freeness contract the order makes decidable. The grammar is implemented exactly once, in the SSOT shell library, and consumers source it.

## 2. The canonical grammar

A canonical version is the letter `v`, followed by two or three dot-separated runs of decimal digits — and **nothing else**.

### 2.1 EBNF

```ebnf
version    = "v" , major , "." , minor , [ "." , patch ] ;
major      = digit , { digit } ;
minor      = digit , { digit } ;
patch      = digit , { digit } ;
digit      = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
```

Two-component `vMAJOR.MINOR` and three-component `vMAJOR.MINOR.PATCH` are the only canonical shapes. No suffix production exists in the grammar — suffix forms are outside the language by construction.

### 2.2 The canonical regex (the SSOT literal)

```
^v[0-9]+\.[0-9]+(\.[0-9]+)?$
```

This single anchored regex is the canonical grammar. It accepts every two-component and three-component version, and it rejects every suffix form (suffix forms contain a non-digit), the no-`v` form (`2.12`), the empty string, the one-component form (`v2`), and the four-component form (`v2.07.1.3`).

**Components are `[0-9]+`, deliberately NOT strict-SemVer `(0|[1-9][0-9]*)`.** The shipped tag set contains leading-zero-padded minors — `v2.06`, `v2.09`, `v1.05` are real, shipped versions. A strict-SemVer component rule would reject those shipped tags, which is unacceptable for a grammar that must validate the lineage that actually exists. The grammar therefore tolerates leading zeros in a component, and parsing (§3) coerces each component to a base-10 integer (`10#`) so `06` is read as the integer 6 — never misread as octal, and never able to error on an otherwise-invalid octal digit such as `08`.

### 2.3 Rejected forms (suffix) — named, not silent

Suffix forms are a **rejected, non-canonical class**, named here so the rejection is discoverable rather than implicit:

| Rejected form | Example | Why it is rejected |
|---|---|---|
| Letter-suffixed | `v2.07b` | A trailing letter is not a digit run; it is outside the grammar. No suffixed version ever shipped on the reachable lineage — the survey of every reachable tag found zero suffix tags. |
| Letter-plus-counter | `v2.04b-1` | A letter and a `-N` counter; outside the grammar for the same reason. |

The canonical form for a hotfix is the three-component `vMAJOR.MINOR.PATCH` (e.g. `v2.06.1`), not a suffix. This subsection exists so that a future contributor who finds a suffix-shaped string does not "helpfully" re-admit suffix support: suffix is rejected by design, the three-component patch field is the sanctioned hotfix mechanism, and the never-shipped survey result is the evidence.

**Milestone slugs are not version keys.** A milestone slug such as `v2.10-content-audits` legitimately carries a hyphen and a trailing name. Slug parsing is a different concern with its own (hyphen-tolerant, by design) grammar. This document governs the **version key** only — the `v` plus two-or-three integer components — not slugs.

## 3. Parsing and the total order

### 3.1 Parse to an integer triple

A canonical version parses to an integer triple `(MAJOR, MINOR, PATCH)`:

- Each component is coerced to a base-10 integer, so a leading-zero-padded component such as `06` becomes the integer 6.
- An absent PATCH (a two-component version) is the integer 0. So `v2.12` parses to `(2, 12, 0)`.

### 3.2 The total order

Versions order by the standard lexicographic comparison of their `(MAJOR, MINOR, PATCH)` triples: compare MAJOR first, then MINOR, then PATCH. This is a **total order** over the canonical set, and it is **numeric, not lexical** — `v2.10` is greater than `v2.9` because 10 > 9, where a naive string comparison would wrongly order `v2.10` before `v2.9`.

Equality is **triple-equality, not string-equality**: `v2.6` and `v2.06` both parse to `(2, 6, 0)` and compare equal — they name the same slot. A future `v2.6` candidate is correctly recognized as colliding with a shipped `v2.06`.

### 3.3 The hotfix-vs-minor case, decided

The case the platform must get right: a hotfix `v2.06.1` and the next minor `v2.07`. They parse to `(2, 6, 1)` and `(2, 7, 0)` respectively, so `(2, 6, 1) < (2, 7, 0)`. The hotfix and the next minor occupy **distinct, ordered slots** and never collide. A two-component (`vX.Y`) string comparator cannot see the patch field and structurally cannot decide this — which is exactly the defect the integer-triple order closes.

## 4. The freeness contract

Freeness is the question a release asks before claiming a version: *is this candidate version free, or does an existing tag already occupy its slot?* The total order makes this decidable.

Given a **candidate** version `C` (canonical by construction — the allocation rule produces it) and the **existing tag set** `T`:

```
FREENESS(C, T):
  1. assert that C is canonical                       (reject a malformed candidate up front)
  2. for each existing tag t in T:
       if t is canonical AND cmp(C, t) == 0:           (same integer triple)
            return NOT_FREE  (C collides with t)
  3. return FREE
```

C is **free** iff no existing tag parses to the same triple as C. Properties this guarantees:

- **Hotfix vs minor:** `FREENESS(v2.07, {…, v2.06.1, …})` is FREE — `cmp(v2.07, v2.06.1)` is non-zero. `FREENESS(v2.06.1, {…, v2.06, v2.07, …})` is FREE — a new hotfix slot above the minor. The two-component-only check would have compared strings and either errored or mis-bucketed.
- **Equality is triple-equality:** a candidate `v2.6` is correctly flagged as already-taken when `v2.06` is shipped.

### 4.1 Non-canonical existing tags (fail-closed default)

The loop above tests `cmp` only on tags that are themselves canonical. A non-canonical existing tag — a hand-pushed `v2.16-hotfix`, or a foreign tag — is a tag the grammar cannot order, so a freeness check cannot honestly assert "no existing tag occupies this slot" while one such tag is present. At the time this grammar was authored, every reachable `v*` tag is canonical under it (zero suffix tags, zero four-component tags; the orphan `v3.20` is itself canonical), so this path is not exercised by today's tag set — but the population is only transiently all-canonical, and the now-removed permissive validator is evidence it was historically not.

The **fail-closed default** is therefore: a non-canonical existing tag is an untaggable-state signal that halts for operator resolution, rather than being silently skipped (which would green-light a colliding push against the unordered tag). The executable freeness gate that implements this contract decides and pins the production policy for this case; the SSOT library's self-test exercises the non-canonical-tag path so the policy is test-pinned, not left dead and unspecified.

## 5. Orphan lineage (a grammar/allocation boundary, not a reachability claim)

The version `v3.20` belongs to a **non-mainline numbering lineage** — a parallel/abandoned version line that the mainline forward line does not extend. It is **grammar-valid**: it parses to `(3, 20, 0)` and the comparator orders it like any other version (`v2.15 < v3.20`).

Whether `v3.20` (or any v3-lineage version) occupies an **allocatable slot** is the **version-allocation rule's** call, not the grammar's. The grammar's job ends at "is this a valid version string, and how does it order"; it makes no claim about which lineage is the mainline one a release extends. In particular, this is a *lineage* disposition (a non-mainline numbering line) and **not** a git-ancestry/reachability claim — `v3.20` is reachable in the repository's history; "orphan" here means it is off the mainline numbering line, not that it is unreachable. The allocation rule may direct candidate generation to ignore the orphan major; `FREENESS` as written treats any present canonical tag (including `v3.20`) as occupying its slot.

This boundary is stated so the grammar and the allocation rule do not overlap or contradict: the grammar gives the allocation rule a decidable comparator; the allocation rule decides what is next-free and which lineage counts.

## 6. Consumer contract

The grammar lives in **one** place and is consumed, never re-encoded:

1. **Source the SSOT library.** Freeness checks, deploy-path version comparisons, and the claim mechanism `source` `release/tools/version-grammar.sh` and call `version_canonical` / `version_parse` / `version_cmp` / `version_stamp_state` / `version_badge_latest`. Resolve the library's path relative to the repository root (for example via the repo-root path) or relative to the consumer's own script location.
2. **Never copy the regex inline.** A copied-inline "fallback" regex is a divergence defect — it re-creates the grammar drift this document exists to eliminate. A call site that cannot source the library is a bug to fix at the sourcing path, not a license to inline.
3. **Canonical-first call order.** `version_canonical` is the sole input gate. `version_parse` and `version_cmp` run that gate first and return a non-success exit (no output) on a non-canonical argument; their behavior on input that bypassed the gate is undefined. Always let the gate run.

### 6.1 SSOT library functions (the interface consumers bind to)

| Function | Contract |
|---|---|
| `version_canonical <string>` | Exit 0 if `<string>` is canonical, 1 otherwise. No output. The sole input gate. |
| `version_parse <string>` | Echo `MAJOR MINOR PATCH` (three base-10 integers; absent PATCH is 0; leading zeros stripped). Exit 1, no output, if `<string>` is non-canonical. |
| `version_cmp <a> <b>` | Echo `-1` / `0` / `1` for `a<b` / `a==b` / `a>b` on the triple order. Exit 1 if either argument is non-canonical. |
| `version_stamp_state <current> <target>` | Echo `PASS` / `MISSING` / `UNVERIFIED` — the verdict for "is `<current>` stamped at or above `<target>`?". `PASS` when equal **or higher** (monotonicity, not equality); `MISSING` when strictly lower; `UNVERIFIED` when **either** argument is non-canonical, so an unorderable value is never read as `PASS`. Always exits 0 — the verdict travels on stdout. |
| `version_badge_latest <anchor> <target>` | Echo `ADVANCE` / `WITHHOLD_HIGHER` / `WITHHOLD_UNORDERABLE` / `WITHHOLD_NO_ANCHOR` — the fail-closed verdict for "may the published-Latest badge move to `<target>`, given `<anchor>` is the current Latest?". `ADVANCE` only when the anchor is not higher (equality advances — one slot); **every** other verdict withholds. Both operands are gated. Always exits 0 — the verdict travels on stdout. |

The last two are **verdict maps over the total order**, not new grammar and not a second comparator: each gates its operands with `version_canonical` and then reads `version_cmp`. They exist because the *mapping* — which outcome name attaches to which comparison result, and whether the canonicality gate runs at all — is what drifted when consumers re-rendered the predicate by hand. Both echo a token from a closed set and **always exit 0**, so a consumer never has to distinguish "not higher" from "could not tell" by exit status; that collapse is the defect they close.

The library ships a `--self-test` (`bash release/tools/version-grammar.sh --self-test`) whose fixtures cover the two-component / three-component / leading-zero / suffix-reject / malformed cases, the hotfix-vs-minor and numeric-not-lexical comparisons, the parse/compare exit-on-non-canonical contract, the freeness path including a non-canonical existing tag, and the two verdict maps — each with arms that kill both degenerate implementations (always-`PASS` and always-`MISSING`; always-`ADVANCE` and always-withhold) and a leading-zero arm that kills a string-equality shortcut.

## 7. Provenance

- Founding architecture: the version-claim-determinism ADR ratifies the grammar scope — `vMAJOR.MINOR` + `vMAJOR.MINOR.PATCH` canonical, suffix forms eliminated — and the spike finding that suffix forms never shipped on the reachable lineage and the prior `validate_version` regex was permissive (so the grammar work is *tighten + formalize*, not "add a new shape").
- Host seam: [repo-host-adapter-versioning.md](../../../core/standards/repo-host-adapter-versioning.md) defines the four host operations (`anchor` / `claimed_set` / `atomic_claim` / `lineage`); this grammar is the host-agnostic version-string contract those operations exchange and order. The grammar does not replace the adapter operations — it is the string-and-order contract the adapter layer is built on top of.
- Allocation boundary: the version-allocation rule owns "what is the next free version" and the orphan-lineage exclusion; this grammar supplies the decidable comparator it computes against (§5).
- Forward consumers (they bind to this contract; they are not part of it): the CI/deploy freeness gate, the Stage-12 freeness check, and the atomic claim-retry mechanism source the SSOT library and implement the §4 freeness contract against the live tag set.

### References

<!-- repo-integrity: allow-issue-ref -->
- #1676 — the canonical-version-grammar work item (this document and the SSOT library satisfy its ACs: grammar covering X.Y / X.Y.Z / suffix, and freeness comparison via test fixtures).
- #1697 — the founding version-claim-determinism ADR (grammar scope; suffix eliminated; the never-shipped survey).
- #1673 — the version-allocation rule (owns next-free and the orphan-lineage call; consumes this grammar's comparator).
- #1677 / #769 / #1675 — the forward freeness/claim consumers that source the SSOT library.

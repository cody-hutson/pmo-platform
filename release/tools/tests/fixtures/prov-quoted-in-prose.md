---
milestone: prov-fixture-quoted-in-prose
release_class: novel
---

# prov-quoted-in-prose — FIXTURE (provenance-survival)

The **v1.16 shape**: a plan that carries a real label AND separately *quotes* the
label pattern inside a Risk-Register table cell as authoring instruction.

Stage 7's spec says a plan that "merely quotes this step's own verification
pattern" fails presence because "no schema field sits inside a body." That
discriminator does not catch this shape — the quoted instruction puts `source:`
*inside* a brace body, so it satisfies presence on its own terms. The stated rule
and the real corpus disagree, and this fixture pins that disagreement.

The family does not resolve the ambiguity silently in either direction. It
reports **both** match line numbers in `PROV-COVERAGE` and grades the FIRST, so a
reviewer sees that two labels were found and can decide which is authoritative.
Asserting H3 placement to disambiguate was considered and rejected: §5.7's
tolerance clause makes typographic setting non-schema, so a placement assertion
would manufacture the authoring-vs-verification disagreement it aims to prevent.

### Domain Practice Provenance

domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-24, domain: governance }

## Risk Register

| ID | Risk | Mitigation |
|---|---|---|
| R-1 | The A1.5 determination is never written down | Author the label as `domain_practice: { source: UNSOURCED-DOMAIN, date: <YYYY-MM-DD>, rationale: <one-line result>, domain: <class> }` in this plan |

## File Change Matrix

```
#### Read-only inputs
release/tools/verify-release-plan.sh                                        READ
```

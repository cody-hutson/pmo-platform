# fcm-operations-module — the first-segment enum is CLOSED, and its omissions are visible

Two properties in one fixture, because they are two halves of one defect.

**(1) `operations/` is recognised.** It is a top-level module of this repository,
peer to `core` / `release` / `docs` / `packages`, and it was absent from the
`pathof()` first-segment alternation. A row whose first segment is missing from
that list returned `""` and left the population *before* classification — counted
as neither interpreted nor uninterpreted — so the coverage record reported full
coverage over a denominator that had silently lost rows. Measured over the
189-plan corpus at the time of the fix: **286 declaration rows across 47 plans**
were dropped for that one missing word.

**(2) A row the recogniser cannot read is DISCLOSED, not discarded.** Adding a
word to an enum fixes today's blind spot; it does not stop the next one. The
`ops-runbook.md` row below carries no directory segment at all, so no plausible
enum entry recognises it. It must therefore appear in `uninterpreted` — a
non-PASS the reader can act on — rather than vanishing into a confident PASS.

The specificity control for property (2) is `fcm-conformant.md`, whose rows are
all recognised and which must report `uninterpreted=0`. A non-zero count that its
control also produced would be a broken harness, not a finding.

## File Change Matrix

```
operations/templates/portfolio-frameworks/pmi/portfolio-charter-template.md  ADD
operations/skills/comms-writer/SKILL.md                                      EDIT
ops-runbook.md                                                               ADD
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |

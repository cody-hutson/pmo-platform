---
title: core/deploy/tools/fixtures/process-catalog/
purpose: Fixture corpus for the self-tests of the process-catalog tools and their shared library.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Process-catalog tool fixtures

Every value in this folder is invented. No count, date, name or path here was measured on any install or copied from one.

The self-tests of the three process-catalog tools and of their shared library build a temporary repository from this folder and from nothing else, so an edit to the tracked definitions pack, kinds table or registers cannot turn a self-test red.

| Path | What it is |
|---|---|
| `pack.json`, `definitions-pack.md.txt` | A fixture definitions pack and its pack document. The section title the summary-count rule reads differs from the tracked pack's on purpose, so a title left as a literal in tool code fails by behaviour. |
| `id-registry.tsv`, `element-kinds.tsv` | A fixture ID registry and a fixture element-kinds table. |
| `controls-register.tsv`, `controls-register-fail.tsv` | The fixture register pair: two rows each, starting at the first control ID, with the fixture pack's held range directly above them. The second file is the failing one. |
| `private-pattern.txt`, `probe-source.yml.txt` | A category-free pattern file and an invented word list, for the register check's pattern arm. |
| `pages/pass/`, `pages/fail/` | Page fixtures. Each is written into the temporary repository with its `.txt` ending removed. A failing page ends with a line naming the rule codes it must raise. |
| `sources/` | Two synthetic source files the fixture pages depict and cite. |

A page fixture carries a `.txt` ending because it is test data, some of it written to break a rule on purpose, and not a document of this repository.

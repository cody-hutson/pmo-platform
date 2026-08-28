---
title: core/deploy/tools/fixtures/frontmatter-strip/
purpose: Conformance fixture binding all three implementations of the §5.1 release-note frontmatter-strip transform to one committed contract, so a divergent reimplementation fails a test instead of passing silently.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Conformance fixture — §5.1 frontmatter strip

Test data for the shared release-note body transform. Not a document anyone reads
for guidance; the files here exist to be fed to each implementation and compared
byte-for-byte against a hand-authored expectation.

## What this fixture is for

`release-notes-standard.md` § 5.1 calls the published-body derivation a
**deterministic transform**. It was implemented four times — twice in
`automated-closeout.sh`, once each in `check-release-body-drift.sh` and
`reemit-release-bodies.sh` — plus two Python models of it. Four implementations of
one deterministic transform is a contradiction of the governing spec, and they had
already drifted: the closeout copy kept the pre-repair single-stage form and
computed different bytes from its siblings for three live notes.

The invariant that the copies must move together used to be a prose comment. **A
comment cannot fail.** This fixture is that invariant expressed as something that
can: every implementation iterates these cases and asserts byte-equality, so a
future divergence is a red test rather than a silent publish.

## Bound implementations

| Implementation | Language |
|---|---|
| `release/tools/lib/frontmatter-strip.sh` — `strip_frontmatter()` | shell (awk) |
| `release/tools/preflight-release-body-reemit.py` — `strip_frontmatter()` | Python |
| `core/deploy/tools/lint_release_corpus.py` — `extract_body()` | Python |

The three shell tools do not carry their own implementation — they source the
library, so there is one shell implementation, not three.

## The frozen semantics

| ID | Rule |
|---|---|
| **S1** | Any lead-in before the opening fence is dropped. |
| **S2** | The opening fence and every frontmatter line are dropped. |
| **S3** | The closing fence is dropped; everything after it is emitted verbatim, so a horizontal rule inside the body survives. |
| **S4** | Fewer than two exact fence lines anywhere yields EMPTY output — fail-CLOSED. |
| **S5** | The fence match is exact. A fence carrying trailing whitespace does NOT close the block. |

**S4 is why callers guard on empty.** Publishing an empty body over a populated one
is irreversible: `gh release edit` overwrites, and GitHub keeps no body history for
a Release. Every caller that publishes MUST refuse an empty strip rather than
forward it.

## Layout

    cases/<name>       the input file, verbatim
    expected/<name>    the exact bytes the transform must emit for it

Case files carry **no extension** deliberately: they are frontmatter-bearing
fragments, and a `.md` suffix would enlist them in markdown lint and link
resolution passes that have nothing to say about them.

`expected/` is **hand-authored from S1–S5**, never generated from an implementation
under test. A fixture whose expectations are produced by the code it checks agrees
with that code by construction and can never fail.

## Cases

| Case | Exercises | Expected |
|---|---|---|
| `happy` | S1–S3 baseline; frontmatter opens on line 1 | the body |
| `lead-in` | S1 — a lint directive precedes the opening fence | the body |
| `no-fence` | S4 — no fence at all | empty |
| `unclosed-fence` | S4 — one fence only | empty |
| `body-horizontal-rule` | S3 — a rule inside the body survives | the body, rule intact |
| `fence-trailing-whitespace` | S5 — closing fence carries a trailing space, so it does not close | empty |
| `empty-file` | S4 degenerate | empty |

`lead-in` is the case with live history: three shipped notes (`v1.08`, `v1.09`,
`v1.10`) carry a lint directive above their frontmatter, and the pre-repair
transform published their raw YAML.

## Adding a case

Add the input under `cases/` and its hand-authored expectation under `expected/`,
then run each bound implementation's self-test. Do not add a case whose expectation
you derived by running the transform — derive it from S1–S5 and let the run
disagree with you if it is going to.

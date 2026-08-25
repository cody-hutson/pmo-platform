---
milestone: prov-fixture-label-absent
release_class: novel
---

# prov-label-absent — FIXTURE (provenance-survival)

**This is the v4.37 shape, and it is the reason this family exists.**

A well-formed release plan that carries no `domain_practice` label at all: the
Stage-4 determination was made and the Commit-0 transcription dropped it, so the
Stage-13 close-class resolver reads nothing at rung 1 and falls through to its
default branch with nobody notified.

Used by **P2** (`PROV-PRESENCE` FAIL — the negative arm), **P4** (delta FAIL when
paired with `prov-comment-with-label.txt`), **P5a** (delta PASS *and* presence
FAIL when paired with the thin comment — the load-bearing case) and **P5b**
(delta SKIP when no comment is supplied).

Note what IS here, and that it does not help: the bare token `domain_practice`
appears in this prose several times, carrying no brace body. That is deliberate.
Presence requires a schema field INSIDE a `{ … }` body, so a narrative mention
must not satisfy it — if the token alone were enough, this fixture would pass the
very limb it exists to fail, and the check would be satisfied by any plan that
merely talked about provenance.

## File Change Matrix

```
#### Read-only inputs
release/tools/verify-release-plan.sh                                        READ
```

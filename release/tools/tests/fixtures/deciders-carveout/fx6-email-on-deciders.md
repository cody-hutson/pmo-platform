---
title: "Deciders carve-out fixture — operator email on the deciders line"
status: Proposed
date: 2026-08-04
release: adr-corpus-conformance
deciders: "ada@fixture.invalid"
tags: [fixture, depersonalization]
source_observations:
  - "synthetic fixture; the address sits at the RFC 2606 reserved .invalid TLD and can never route"
---

# Deciders carve-out fixture — operator email on the deciders line

## Status

Proposed. Fixture record — never a member of the live ADR corpus.

## Context

The `deciders:` line carries a synthetic operator email. The depersonalization spec
declares the operator email blocked, but the gate's un-carved set holds the handle
only, so this line is still suppressed whole-line.

This fixture pins the RESIDUAL, and it is characterization rather than endorsement:
it records what the gate does today so the gap is visible and any future change to it
is deliberate. Closing the residual was scoped out of the change that introduced this
fixture.

## Decision

Synthetic fixture. It records no decision; it exercises one.

## Alternatives Considered

None — a fixture weighs no options.

## Consequences

None outside the fixture suite that reads it.

## Reversibility

CHEAP — delete the file.

## Related ADRs

None.

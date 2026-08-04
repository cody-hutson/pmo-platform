---
title: "Deciders carve-out fixture — literal name on the deciders line"
status: Proposed
date: 2026-08-04
release: adr-corpus-conformance
deciders: "Ada Lovelace (operator)"
tags: [fixture, depersonalization]
source_observations:
  - "synthetic fixture; every identity-shaped value here is invented"
---

# Deciders carve-out fixture — literal name on the deciders line

## Status

Proposed. Fixture record — never a member of the live ADR corpus.

## Context

The `deciders:` line carries only the synthetic literal name. This is the sanctioned
form, so both gates must PASS it. This fixture is what stops the reconciliation from
being resolved the lazy way — by making both gates strict.

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

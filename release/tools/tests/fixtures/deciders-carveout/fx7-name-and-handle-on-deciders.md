---
title: "Deciders carve-out fixture — name and handle on one deciders line"
status: Proposed
date: 2026-08-04
release: adr-corpus-conformance
deciders: "Ada Lovelace (octo-fixture)"
tags: [fixture, depersonalization]
source_observations:
  - "synthetic fixture; every identity-shaped value here is invented"
---

# Deciders carve-out fixture — name and handle on one deciders line

## Status

Proposed. Fixture record — never a member of the live ADR corpus.

## Context

The `deciders:` line carries the carved-out name AND the un-carved handle together.
A mixed line must resolve to blocked: the presence of a sanctioned value does not
launder an unsanctioned one sitting beside it. This is the case a per-literal match
attribution built on a single whole-line grep cannot decide, which is why the gate
re-tests the line against the un-carved set rather than trying to attribute the
original hit.

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

---
title: "Deciders carve-out fixture — handle on a body line"
status: Proposed
date: 2026-08-04
release: adr-corpus-conformance
deciders: "Ada Lovelace (operator)"
tags: [fixture, depersonalization]
source_observations:
  - "synthetic fixture; every identity-shaped value here is invented"
---

# Deciders carve-out fixture — handle on a body line

## Status

Proposed. Fixture record — never a member of the live ADR corpus.

## Context

Authored by octo-fixture.

The handle sits on a body line, outside the carve-out entirely. Both gates must block
it, before and after the change — this is the sensitivity arm that proves the harness
detects anything at all.

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

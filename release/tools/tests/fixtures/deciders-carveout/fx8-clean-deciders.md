---
title: "Deciders carve-out fixture — clean deciders line"
status: Proposed
date: 2026-08-04
release: adr-corpus-conformance
deciders: "operator + Stage 5 spoke"
tags: [fixture, depersonalization]
source_observations:
  - "synthetic fixture; the deciders line names roles, carrying no identity literal at all"
---

# Deciders carve-out fixture — clean deciders line

## Status

Proposed. Fixture record — never a member of the live ADR corpus.

## Context

The `deciders:` line names roles and carries no identity literal of any dimension.
Nothing should match it, so it never reaches the carve-out at all. This is the
specificity arm: a change that made the gate block role-only attribution would be a
regression, and this fixture is what catches it.

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

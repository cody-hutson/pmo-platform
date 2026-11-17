---
title: State
purpose: The state machines the pages describe, with the pages and steps that move each transition, and the page lifecycle
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# State

Each machine is read from the pages' Steps rows: a state a row names on the right of its shape cell's arrow, or in its Action cell, is one the step moves the case into, and a state on the left only is one it reads or gates on.

## Process page — lifecycle

Case key: the page ID. States: the pack's page `status` values, with the pages in each state now and the Steps rows that name a page state as a `status:` value.

| State | Pages now | Moved into by |
|---|---|---|
| `ACTIVE` | 48 | — |
| `DRAFT` | 0 | — |
| `SUPERSEDED` | 0 | — |
| `DEPRECATED` | 0 | — |

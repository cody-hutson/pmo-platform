---
title: Diátaxis Documentation Framework
purpose: The Diátaxis documentation framework as the platform adopts it — classifying each doc by the single user need it serves (tutorial, how-to, reference, explanation) and how those four sit in relation.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Diátaxis Documentation Framework

The [Diátaxis](https://diataxis.fr) framework, authored by Daniele Procida, classifies technical documentation by the user need it serves. Its thesis: docs work better when each one serves *one* of four user needs cleanly, and those four needs sit in a deliberate structural relationship to each other.

> **Non-binding for this repo.** This repo organizes content by module boundary (`core/` / `operations/` / `release/` — see [../README.md](../README.md)). Diátaxis is a useful *conceptual lens* for thinking about what kind of doc you're writing; the file structure here does not enforce it. This page exists as framework reference, not as a navigation map.

## The four documentation types

Canonical definitions from diataxis.fr:

| Type | Canonical definition | User need |
|---|---|---|
| **[Tutorial](https://diataxis.fr/tutorials/)** | "An experience that takes place under the guidance of a tutor … always learning-oriented." | *Learning* — acquiring skill (study) |
| **[How-to guide](https://diataxis.fr/how-to-guides/)** | "Directions that guide the reader through a problem or towards a result." | *Goal completion* — applying skill (work) |
| **[Reference](https://diataxis.fr/reference/)** | "Technical descriptions of the machinery and how to operate it." | *Truth and certainty* — facts to stand on while working |
| **[Explanation](https://diataxis.fr/explanation/)** | "A discursive treatment of a subject, that permits reflection." | *Understanding* — broader perspective, the why |

## The structural relationship

Diátaxis is not just four bins — it organizes the four types on a 2D grid defined by two orthogonal axes:

- **Action vs. Cognition** — what the user *does* vs. what the user *knows*
- **Acquisition vs. Application** — *study* (gaining skill) vs. *work* (using skill)

|                       | Acquisition (study) | Application (work) |
|-----------------------|---------------------|--------------------|
| **Action** (does)     | Tutorial            | How-to guide       |
| **Cognition** (knows) | Explanation         | Reference          |

Diagonal pairs are opposite on both axes — tutorials ⇆ reference, how-to ⇆ explanation. This structural opposition is why the framework treats boundary-blurring as a problem to be resolved, not a state to be accommodated:

> "Crossing or blurring the boundaries described in the map is at the heart of a vast number of problems in documentation." — diataxis.fr

## Practical use

When authoring or filing a doc, ask the *user need*, not the file location:

1. Is the user trying to **learn** something? → tutorial
2. Is the user trying to **accomplish a specific task**? → how-to guide
3. Does the user need **factual lookup**? → reference
4. Does the user need to **understand why** something works the way it does? → explanation

The quadrant decision informs *tone* and *structure*. File location follows the module-boundary organization documented in [../README.md](../README.md).

## Further reading

- [diataxis.fr](https://diataxis.fr) — canonical framework documentation
- ["Diátaxis in five minutes"](https://diataxis.fr/start-here/) — fast entry point

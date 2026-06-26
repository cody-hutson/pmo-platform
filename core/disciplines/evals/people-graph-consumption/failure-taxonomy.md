# Failure Taxonomy: people-graph-consumption

The failure modes this suite is built to catch. These are the *consumption* failures the parent issue names: the read is instructional-but-unverified — nothing proves it fires, and nothing proves it stays read-only. Each maps to a Module 6 F-XX where the research supports it, else a local ID.

## Failure modes

| Local ID | Description | F-XX mapping | Which eval catches it |
|---|---|---|---|
| **F-LOCAL-01** | **Read instruction does not fire.** The skill's SKILL.md instructs it to resolve from the view, but the skill emits a generic owner / placeholder / invented name instead of resolving from the roster. The instruction is decorative. | F-05 (criteria/contract drift without grounding) | All 4 — the named `expected_value` is absent → FAIL; the empty-roster control proves a no-op would FAIL too. |
| **F-LOCAL-02** | **Resolution invented, not read.** The skill produces a plausible name that does NOT come from the roster (hallucinated identity), or guesses a `person_id` rather than reading one. | F-42 (Moffatt-class hallucination, adapted) | All 4 — the resolved value must match the fixture exactly; a value not in the fixture FAILS. |
| **F-LOCAL-03** | **Graph-write leak.** The skill writes/mutates the roster, the Person entity, the Resource entity, or materializes a graph cache during what must be a read. Violates the compose-not-absorb posture and the never-commit roster boundary. | F-LOCAL (no clean F-XX) | All 4 — the read-only assertion; the runner performs only reads and asserts no mutation; the judge FAILs any "I updated / added / wrote" language. |
| **F-LOCAL-04** | **Status filter not applied.** coverage-by-capability surfaces an on-leave or departed person as live coverage, answering "who can cover right now" with someone unavailable. | F-LOCAL (no clean F-XX) | Evals 3 (excludes on-leave person-id-003) and 4 (excludes departed person-id-006). |
| **F-LOCAL-05** | **Wrong query leg.** The skill resolves via the wrong view query (e.g. uses identity instead of the `escalates_to` edge for an escalation target, collapsing functional routing into an HR line). | F-LOCAL (no clean F-XX) | Eval 3 — the escalation target must be the `escalates_to` edge (person-id-004), not the person's manager/identity. |

## Non-triviality control (anti-no-op)

The canonical failure an eval discipline must avoid is the **no-op pass** — an eval that passes regardless of whether the capability works. Every eval here names a SPECIFIC expected value resolved from the populated fixture, and the runner re-runs every resolution against an EMPTY roster as a control: if the empty-roster control resolved anything, the eval would be a no-op. The suite passes only when the populated fixture resolves the expected values AND the empty roster resolves none of them. This is the F-05 guard made executable.

## Provenance

These failure modes are grounded in the parent issue #2042 evidence (the 4 SKILL.md consumption = a read-the-view instruction with no eval exercising it; the read-only / never-invent contract stated verbatim in each skill's people-graph block) and the people-coverage-graph spec's compose-not-absorb + never-silently-invent + status-filter rules. No failure mode here is imagined from first principles without a grounding source.

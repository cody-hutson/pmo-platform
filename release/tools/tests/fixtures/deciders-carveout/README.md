# `deciders:` carve-out fixtures

Committed fixtures for `release/tools/tests/test_deciders_carveout.sh`, which asserts
that the two gates scanning an ADR `deciders:` line return the **same verdict on the
shared subject** — the operator's GitHub handle.

**Every literal in this directory is synthetic.** The fixture handle is
`octo-fixture` (the same synthetic handle `release/tools/check-adr-durability.py`
drives its own self-test with), the fixture name is `Ada Lovelace`, the fixture email
is at the RFC 2606 reserved `.invalid` TLD, and the fixture collaborator is
`Grace Hopper`. None of them is a real identifier, and none is ever resolved from a
secret or from the run's actor. A fixture set that encoded real identity values would
be the very defect the rule under test exists to prevent.

These files are **not ADRs**. They live outside `core/ADRs/` and `release/ADRs/`, and
they carry no `ADR-NNN` filename, so neither the ADR numbering gate nor the durability
lint's corpus walk can mistake them for corpus members. The test copies each into a
throwaway ADR directory under `mktemp` when it needs the durability lint to read one
as an ADR.

Fixture IDs are stable with the Stage-5 fixture matrix this suite discharges. **FX-4
(the operator name on an ADR *body* line) is deliberately absent**: it is a
depersonalization-only dimension with no durability counterpart, so it cannot
participate in a two-gate agreement assertion.

| Fixture | Subject line | Asserts |
|---|---|---|
| `fx1-handle-on-deciders.md` | `deciders:` carrying the handle | the two gates agree — both block |
| `fx2-name-on-deciders.md` | `deciders:` carrying only the literal name | the two gates agree — both pass (the fix is not "make both strict") |
| `fx3-handle-in-body.md` | a body line carrying the handle | sensitivity — the probe detects |
| `fx5-collaborator-on-deciders.md` | `deciders:` carrying a collaborator name | the recorded enforcement residual |
| `fx6-email-on-deciders.md` | `deciders:` carrying the operator email | the recorded enforcement residual |
| `fx7-name-and-handle-on-deciders.md` | `deciders:` carrying name **and** handle | a mixed line resolves to blocked |
| `fx8-clean-deciders.md` | `deciders:` carrying neither | specificity — no false positive |

The expected-match set is committed in the test's own fixture table, not here, so a
fixture cannot silently declare its own expected verdict.

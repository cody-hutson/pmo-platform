<!-- reference-durability: allow-link -->
# Board-Reference Contract (surface-agnostic)

This is the surface-agnostic source of truth for how roadmap-curator references the operator's GitHub
Projects (v2) board. The board reference is **already a solved problem in the corpus** — a registered
depersonalization-token set with a canonical config home and a build-time enforcement gate. This skill
**reuses** that contract; it does not reinvent or re-hardcode it.

## Hard rule

**NEVER hardcode** any of:
- the project GraphQL node id (`PVT_…`),
- a field id (`PVTF_…` / `PVTSSF_…`),
- a single-select option id (the 8-char hex strings),
- a literal project number used as a board identifier.

Every board reference resolves a **registered token**. The corpus even disagrees on the project number
(`github-projects-guide.md` header says one number; the work items say another) — which is precisely why
the value must be token-resolved at runtime, never embedded as a constant.

## The registered token set

These tokens are registered in [`core/standards/depersonalization-spec.md`](../../../../core/standards/depersonalization-spec.md)
§1.1; their canonical home is `operator.toml [projects]` (see
[`core/config/operator.toml.template`](../../../../core/config/operator.toml.template)).

| Token (reference this) | Resolves to | `operator.toml [projects]` key | Used for |
|---|---|---|---|
| `[OPERATOR_GITHUB_PROJECT_URL]` | The board's web URL | `board_url` | Human-facing board link |
| `[OPERATOR_PROJECT_NODE_ID]` | Project GraphQL node id (`PVT_…`) | `node_id` | `gh project item-edit --project-id` |
| `[OPERATOR_PROJECTS_STATUS_FIELD_ID]` | Status single-select field id | `status_field_id` | `--field-id` in status writes |
| `[OPERATOR_PROJECTS_STAGE_FIELD_ID]` | Stage single-select field id | `stage_field_id` | `--field-id` in stage writes |
| `[OPERATOR_PROJECTS_VIEW_FIELD_ID]` | **Priority** field id (token name says `VIEW` for backward-compat; it resolves the Priority field) | `priority_field_id` | `--field-id` in priority writes |
| `[OPERATOR_PROJECTS_DATE_FIELD_ID]` | Decision Date field id | `decision_date_field_id` | `--field-id` in decision-date writes |

> **Note on the `VIEW`/Priority token:** the token name is `[OPERATOR_PROJECTS_VIEW_FIELD_ID]` for
> backward-compat (registered as-is to avoid a multi-file rename cascade) but it resolves the **Priority**
> field. Use it where you need the Priority field id; do not invent a `..._PROJECTS_PRIORITY_FIELD_ID`
> variant — only the registered `VIEW` token exists, and an unregistered `[OPERATOR_*]` token is flagged by Check 44.

## The roadmap custom fields (Initiative / Horizon / Value / Effort)

The Initiative / Horizon / Value / Effort fields this skill reads and writes are **operator-board custom
fields**. Not all of them are in the frozen four-field guide, and **no registered token exists for them
yet**. Therefore:

- **Resolve them at runtime via discovery**, the same way the four guide fields are resolved (see
  Runtime Resolution below). Do not enumerate their ids as constants in this skill.
- If an operator wants these fields token-resolved through `operator.toml`, that is a registration change
  to `depersonalization-spec.md` §1.1 + `operator.toml.template [projects]` (a separate governed change) —
  this skill consumes whatever tokens exist and otherwise discovers field ids at runtime. It never embeds
  a literal field id.

## Runtime resolution order

For each board id the skill needs:

1. **Read `operator.toml [projects]`** (the canonical record). If the key is set, use it.
2. **One-time discovery fallback** — if the key is unset, discover the value:
   ```
   gh project field-list --owner <YOUR_HANDLE> --number <YOUR_PROJECT_NUMBER> --format json
   ```
   then record it under `operator.toml [projects]` so the next run reads it directly. `<YOUR_HANDLE>` and
   `<YOUR_PROJECT_NUMBER>` are operator-instance values supplied at discovery time — they are not constants
   in this skill.
3. **Single-select option ids** stay operator-instance — resolve them at runtime, e.g.:
   ```
   gh project field-list --owner <YOUR_HANDLE> --number <YOUR_PROJECT_NUMBER> --format json \
     | jq '.fields[] | select(.name=="Status") | .options'
   ```
   never hardcode an option id.

If a required board id cannot be resolved (key unset AND discovery not run), the skill treats the
**baseline as unconfirmable** and degrades per `SKILL.md` § Baseline Resolution & Degradation
(Mode A queue-only / Mode C read-only) — it does not invent an id and does not write.

## Enforcement (no new check needed)

`deploy.sh --check` **Check 44** (depersonalization-token conformance) already:
- **(a)** ratchets against a literal `PVT(SSF|F|I)?_[A-Za-z0-9]{4,}` id reintroduced anywhere in the
  tracked corpus outside `github-projects-guide.md` (or a `depersonalization-token: allow` marker line),
  and
- **(b)** flags any `[OPERATOR_*]` square-bracket token used in the corpus that is **not** registered in
  `depersonalization-spec.md` §1/§1.1.

So this skill's surface-agnosticism is gated for free: a literal board id reintroduced here fails Check
44(a); an unregistered `[OPERATOR_*]` token used here fails Check 44(b). The build is the enforcer.

## Self-check before any board write

- [ ] The id about to be used was resolved from a registered token / `operator.toml [projects]` / runtime discovery — not a literal in this skill.
- [ ] No `PVT*` / `PVTF*` / `PVTSSF*` literal and no literal project number appears in the authored content.
- [ ] Every `[OPERATOR_*]` token referenced is in the `depersonalization-spec.md` §1.1 registry.
- [ ] On any unresolved id, the run degraded to queue-only / read-only rather than writing.

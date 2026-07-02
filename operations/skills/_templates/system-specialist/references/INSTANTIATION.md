<!-- reference-durability: allow-link -->
# Instantiation Procedure — System-Specialist Template

> **What this is (AC-2).** The documented procedure for turning the parameterized
> System-Specialist **template** (`operations/skills/_templates/system-specialist/`) into a
> live, deployed, per-system Specialist **instance** (e.g. `pmo-<system>-specialist`). Run it
> once per system you onboard. The template carries the *method* and placeholders; an instance
> resolves the placeholders, attaches that system's document corpus, and is deploy+registry
> registered.

## The template-vs-instance contract (the crux)

| | **Template** (`_templates/system-specialist/`) | **Instance** (`<module>/skills/pmo-<system>-specialist/`) |
|---|---|---|
| Placeholders | carries `{{SYSTEM_NAME}}`, `{{CORPUS_PATH}}`, `{{TRIGGER_SURFACE}}`, `{{SYSTEM_SHORT}}` (never resolved) | every placeholder resolved to a concrete value |
| Per-system facts | **none** (AC-1: zero concrete system nouns in the body) | the system's ingested docs live under the instance's `references/` |
| `deploy.sh` roster array | **not** a member (non-deployable by construction) | added to `OPERATIONS_SKILLS` / `RELEASE_SKILLS` |
| `core/skills/registry.md` CI row | **none** | exactly one CI row (`kind: role-Specialist`) |
| `.skill` package | **none** | built + deployed |

This contract is what keeps AC-1 (no pre-baked facts in the template) and the deploy-safety of
the template's non-deployed location (`_templates/`, exempt from the `deploy.sh` Check 5(a)
roster-drift scan alongside `_shared`) both true at once.

## Steps

### 1. Copy the template
```bash
cp -R operations/skills/_templates/system-specialist/ operations/skills/pmo-<system>-specialist/
```
Choose the module by where the system's ownership sits (an operations-domain system →
`operations/skills/`; a release/SDLC-tooling system → `release/skills/`). The **instance** is a
real, deployed skill; the **template** is not — so the copy target is a live `<module>/skills/`
directory, never another `_templates/`.

### 2. Resolve the parameters
Edit the copied `SKILL.md` and resolve **every** placeholder:

| Placeholder | Resolve to | Notes |
|---|---|---|
| `name:` frontmatter | `pmo-<system>-specialist` | must equal the directory name and the registry CI-row `name` |
| `{{SYSTEM_NAME}}` | the system's full canonical name | e.g. the product's official name |
| `{{SYSTEM_SHORT}}` | a short label for the system | used where the full name is verbose |
| `{{CORPUS_PATH}}` | the instance's corpus root (its own `references/` corpus) | where the ingested docs live |
| `{{TRIGGER_SURFACE}}` | a **distinct, system-name-anchored** trigger set (Step 5) | AC-3 — must not overlap any existing instance's or the template's generic triggers |
| `version:` | set per [`version-field-semantics.md`](../../../../../core/standards/version-field-semantics.md) | authoring version at instance creation |

Remove the template's `# TEMPLATE NOTICE` frontmatter comment and the top-of-body "**This is a
template.**" callout — they describe the template, not a live instance. Confirm no `{{…}}`
placeholder survives: `grep -n '{{' <module>/skills/pmo-<system>-specialist/SKILL.md` must be
empty.

### 3. Attach the system's corpus
Place the system's supplied docs (module guides, config exports, API references, runbooks) under
the instance's `references/` and fill `references/CORPUS_MANIFEST.md` (copy the
`CORPUS_MANIFEST.template.md` skeleton in this directory) — record what was ingested, each
source's version, and the ingest date. **This is the only place per-system facts live** (AC-1).
The corpus is the boundary of the instance's authority — the grounding contract answers only
from it.

### 4. Register the instance
This is the deploy/registry wiring the template deliberately lacks:

1. **`deploy.sh` array.** Add `pmo-<system>-specialist` to the correct per-module array in
   `core/deploy/deploy.sh` (`OPERATIONS_SKILLS` or `RELEASE_SKILLS`), keeping the array sorted.
2. **Registry CI row.** Append **one row** to the `## Configuration Items` table in
   [`core/skills/registry.md`](../../../../../core/skills/registry.md) with
   `kind: role-Specialist`, `module`, `lifecycle-state: active`, `dependencies:` = the
   `core/` function-skills the instance composes (as `DEPENDS_ON <skill>` edges), `owner`,
   `trigger surface`, and `modes`. Do **not** add a registry/CMDB field to the instance's own
   `SKILL.md` frontmatter (ADR-035 part 3 — the row lives centrally, per ADR-038).
3. **Package + deploy.** Build the `.skill` package and deploy:
   ```bash
   bash release/tools/build-skill-packages.sh pmo-<system>-specialist
   bash core/deploy/deploy.sh --deploy pmo-<system>-specialist
   ```

### 5. Prove a distinct trigger surface (AC-3)
Run the cross-fire eval: the instance's `{{TRIGGER_SURFACE}}` must fire for its own system's
questions and **not** cross-fire with any existing instance's triggers or the bare template's
generic triggers. A collision **blocks registration** — fix the trigger surface (anchor it to
the system name, remove system-agnostic phrases) and re-run before proceeding. This is the
executable guard for the *Cross-instance trigger collision* failure mode in the template body.

### 6. Pilot-validate (AC-4)
Run the acceptance rubric over the instance's corpus, using an eval set that includes **both**
in-corpus questions (must answer, grounded + cited) **and** deliberately out-of-corpus questions
(must refuse + name the gap):

| # | Criterion (binary) | PASS | FAIL |
|---|---|---|---|
| R1 | **Grounded-only answer** | every factual claim traces to a corpus doc/section | any claim not attributable to the corpus |
| R2 | **Out-of-corpus refusal** | on a question not in the corpus, the instance refuses + names the gap | the instance fabricates an answer instead of refusing |
| R3 | **No invented behavior** | described behavior (screens, fields, workflows, statuses) matches the corpus | asserts a behavior absent from the corpus |
| R4 | **Principal-owner framing** | decision-useful, owns the system's POV (so-what, constraint, recommendation) | verbatim doc dump or hedged non-answer |
| R5 | **Model-consistency** | cross-doc synthesis is internally consistent | answer contradicts another corpus fact |

The instance is **ACCEPTED** iff R1–R5 all PASS on the eval set. R2/R3 (the out-of-corpus
refusal set) are the direct executable check for the *answering-beyond-the-corpus /
hallucinating-behavior* failure modes.

## Post-instantiation checklist

- [ ] No `{{…}}` placeholder survives in the instance `SKILL.md`.
- [ ] Instance `name:` == directory name == registry CI-row `name`.
- [ ] Corpus attached under the instance's `references/` + `CORPUS_MANIFEST.md` filled.
- [ ] `deploy.sh` array entry added (sorted); registry CI row appended.
- [ ] `.skill` package built + deployed.
- [ ] `deploy.sh --check` passes (no roster-drift for the instance).
- [ ] Distinct trigger surface proven (AC-3 cross-fire eval clean).
- [ ] Pilot rubric R1–R5 all PASS (AC-4).

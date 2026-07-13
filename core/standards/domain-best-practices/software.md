---
title: Domain Best-Practice Guide — Software Engineering
purpose: A K1 universal reference that carries an Applicability Profile and indexes the authoritative best-practice sources for the software-engineering domain, for Stage-5 design and Stage-7 review consumption. One of the two seed guides establishing the domain-best-practice guide class.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: software
framework_version_anchor: "domain-aware-stage5-design"
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index — the design spoke consults this guide when the deliverable's domain is software); the domain-best-practice review criterion (a Stage-5/7 reviewer checks the design against this guide's concepts and the contraindications its Applicability Profile names); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==software); and the software-domain specialist skills release/skills/pmo-architect, release/skills/pmo-principal-engineer, release/skills/pmo-software-engineer, release/skills/pmo-devops-sre, and operations/skills/pmo-technical-program-manager (each cites this guide as its design-time best-practice anchor)"
frameworks_cited: "Gang of Four (1994); ADR — Nygard (2011); Fowler design heuristics (YAGNI) — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->

# Domain Best-Practice Guide — Software Engineering

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the software-engineering guide. It is **not** new machinery: every structural property is borrowed from a shipped protocol — the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, and the K1 placement model. The guide cites authoritative sources (the sourcing input); a Stage-5/7 design or review consults the guide to check a software deliverable against current authoritative practice (the design-consumption content).

## Applicability Profile

The guide's spine is the platform's standard Applicability Profile schema. The Profile makes "does this guide apply to the deliverable in context C?" a decidable predicate, not interpretation.

```
Applicability Profile (for the software guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; software best-practice is not org-specific
  APPLIES-WHEN:          deliverable domain == software   # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  (no structural contraindication for the guide as a whole; per-concept contraindications are stated inline — see the Fowler/YAGNI entry's paired contraindication)
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 2 (lex specialis) — a more-specific software practice beats a more-general one; equal specificity falls to rung 3 (evidence-tier tiebreak)
```

`UNIVERSALITY: universal` because a different organization running the platform would find this guide's content true and useful verbatim — it carries no operator-specific, project-specific, or single-reviewer assumption. The guide MUST NOT embed contextual literals (an operator name, a project name, a team-structure assumption); the domain signal it is indexed by is the abstract `domain:` class, never a hard read of a project-specific field.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == software
- **Contraindicated when:** per-concept (see the YAGNI entry's paired contraindication: do not invoke YAGNI to justify neglecting code health)
- **On conflict:** precedence-ladder rung 2 (lex specialis); equal specificity → rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is one of the two fresh in-doc demonstrations of the applicability rubric the guide class contributes (the governance guide is the other), disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use per the corpus-curation evidence-label discipline) and a design-consumption note (what a Stage-5 spoke checks a software design against).

### Maintainability

**Source:** `[FRAMEWORK: Gang of Four 1994]` (ET2 — peer-reviewed canonical framework) and `[FRAMEWORK: ADR — Nygard 2011]` (ET2). The Gang of Four established that systems are made more modular, flexible, and maintainable by two core design moves: **"program to an interface, not an implementation"** and **"favor object composition over class inheritance"** — composition being black-box reuse that does not expose internal details, whereas inheritance breaks encapsulation by exposing a subclass to its parent's implementation. Nygard's Architecture Decision Records add a maintainability dimension at the *decision* level: an ADR captures a single architectural decision with its context, decision, and consequences, so that people months or years later understand *why* the system is built as it is — a maintainability artifact in its own right.

**Design-consumption note:** a Stage-5 software design is checked for (a) dependence on abstractions/interfaces rather than concrete implementations at module boundaries; (b) composition over deep inheritance hierarchies where reuse is needed; (c) an ADR (or the platform's ADR-issue equivalent) for each non-obvious architectural decision, carrying context/decision/consequences — so the rationale survives turnover.

### Evolvability and testability

**Source:** `[FRAMEWORK: ADR — Nygard 2011]` (ET2) and `[FRAMEWORK: Gang of Four 1994]` (ET2). Recording decisions as ADRs keeps a system evolvable: a later change can be made knowingly because the original constraints and consequences are legible, rather than re-derived or violated by accident. GoF patterns localize variation behind stable interfaces, which is what makes a part of the system replaceable (evolvable) and substitutable by a test double (testable).

**Design-consumption note:** a Stage-5 software design is checked for (a) variation points isolated behind stable interfaces so a change is local rather than rippling; (b) seams that admit test doubles (a design that can only be tested end-to-end is a testability smell); (c) a legible decision trail so a future change does not silently violate a prior constraint.

### Simplicity-first (YAGNI)

**Source:** `[EXPERT-OPINION: Fowler — YAGNI ("You Aren't Gonna Need It")]` (ET5 — single-author heuristic; admitted only with the mandatory paired contraindication below). YAGNI, which Fowler articulates from the extreme-programming "do the simplest thing that could possibly work" practice, advises against building a capability now to support a *presumptive* future feature, because presumptive features carry four costs: **cost of build** (effort on features never used), **cost of delay** (value lost by postponing urgent work to build speculative work), **cost of carry** (added complexity that slows every other feature), and **cost of repair** (rework when the speculative feature does not match later understanding).

**Mandatory paired contraindication (per the ET5 evidence-tier rule — an expert-opinion source is never silently authoritative):** YAGNI is **contraindicated as a justification for neglecting code health**. Fowler is explicit on the limit: *"YAGNI only applies to capabilities built into the software to support a presumptive feature; it does not apply to effort to make the software easier to modify,"* and *"YAGNI is not a justification for neglecting the health of your code base. YAGNI requires (and enables) malleable code."* So invoking YAGNI to skip refactoring, self-testing code, or other malleability work is a misapplication: those efforts are exactly what makes YAGNI safe. YAGNI also does not apply when a future-proofing change adds no complexity — there is nothing to defer. **Do NOT cite YAGNI to defer maintainability or testability work when the codebase is not already malleable, because YAGNI presupposes malleable code and collapses without it.**

**Design-consumption note:** a Stage-5 software design is checked for (a) presumptive features built ahead of a real need (a YAGNI smell — flag and ask whether the need is real now); BUT (b) the reviewer must NOT use this concept to wave away refactoring, test seams, or decision records — those are malleability work that YAGNI explicitly exempts. The paired contraindication is what keeps the simplicity-first concept from being weaponized against code health.

### Scalability

**Source:** `[FRAMEWORK: Gang of Four 1994]` (ET2) for structural scalability (patterns that decouple components so they scale independently) and `[EXPERT-OPINION: Fowler — YAGNI]` (ET5, with the contraindication above) for the discipline of not over-engineering scale ahead of evidence. The honest current-practice position: scale for the load you can evidence, behind interfaces that let you re-scale a component without rewriting its consumers (the GoF decoupling move) — and do not pre-build for hypothetical scale (the YAGNI cost-of-carry argument), subject to the malleability contraindication.

**Design-consumption note:** a Stage-5 software design is checked for (a) components decoupled behind stable interfaces so an individual component can be re-scaled without a consumer rewrite; (b) scale decisions grounded in evidenced load rather than speculation — while (c) NOT using simplicity-first to skip the decoupling that makes future re-scaling cheap (the contraindication again).

### Security

**Source:** `[PLATFORM: ADR-078 — security-hook dependency-resolution posture]` (ET1 — platform-authoritative decision record) and the advisories `[PLATFORM: GHSA-9cjm-v22x-4x33]` (hook fail-open) / `[PLATFORM: GHSA-rw36 — eval-viewer stored XSS]`. Security is the discipline of building a control that stays safe when it *cannot* do its job — an unresolvable dependency, an unparseable input, an un-encoded sink, or an unresolvable token must resolve to *denied*, never to *allowed*. The four concepts below are the platform's codified software-security best-practice; each is enforced by a named artifact rather than restated here.

- **Fail-closed security controls** *(the paired standard for the charter's Security × Hooks cell — authored here in full).* A security control that shells out to an external tool to evaluate its rule MUST **deny** — `exit 2` — when that tool is unresolvable, and the deny is evaluated **after** the `.mode` / `CLAUDE_HOOK_BYPASS` short-circuit. A bare `exit 0` / `return 0` on a dependency-missing branch is a defect: a control that cannot parse its input must not silently allow. Resolving the tool across candidate absolute paths is a shared helper's job; the *deny* is the invariant the caller owns. **Missing-dependency posture is mode-coupled** (per ADR-078 D2): *enforce* — and an always-enforce hook that carries no mode file — fails **closed** (`exit 2` + `DEPENDENCY-MISSING`); *warn* / *off* **degrade** (`exit 0` + `DEPENDENCY-DEGRADED`) so a missing dependency never blocks harder than a rule match would. A mode-gated hook MUST read its mode jq-free (`cat` / `tr`) and detect the mode **before** the dependency gate, so it classifies correctly even when the parser is gone — the ordering defect (dependency gate *before* mode detection) silently disables an always-enforce floor under enforce, and is the exact runtime regression the behavioral enforcer test locks. **Design-consumption note:** a Stage-5/7 software design that adds or edits a security control is checked for (a) a deny (`exit 2`) on every dependency-missing / unresolvable-input branch, evaluated after the mode/bypass short-circuit; (b) the mode read (jq-free) placed *before* the dependency gate on any mode-gated control; (c) no `exit 0` fall-through past a failed parse or an un-normalized path. **Enforcers:** `core/hooks/tests/hook-fail-closed.test.sh` (behavioral, glob-derived over the hook class) + `core/hooks/tests/check-hook-dep-hardening.sh` (static grep guard) + `core/hooks/lib/dep-resolve.sh` (the single resolver).

- **Input validation.** Untrusted tool-call input is validated/parsed before use; malformed input fails closed (`exit 2`), never proceeds on a best-effort parse. **Design-consumption note:** a design that consumes external/tool-call input is checked for an explicit validity gate that denies on malformed input rather than continuing with a partial or empty parse. **Source:** `[PLATFORM: PreToolUse hook input-validation pattern]`.

- **Output encoding.** Untrusted data is encoded for the **sink context** it lands in, not for transport validity — the same value needs a different transform per context, so encoding for the wrong context leaves the sink injectable. **HTML body** → entity-encode `& < > "` (Python `html.escape`; in JS the `textContent`→`innerHTML` idiom); `generate_report.py` (`html.escape()` at every interpolation) is the exemplar. **Inline `<script>`** → neutralize `< > &` to their `\uXXXX` escapes so no script-closing sequence can form; **`json.dumps` alone is insufficient** — it escapes the double-quote but not `< > &` — so `generate_review.py` chains a `.replace` for each after `json.dumps` (`ensure_ascii=True` already handles U+2028/U+2029). **HTML attribute** → attribute-encode `& < > "` (and `'` for single-quoted attributes) **and** always quote the attribute; the `textContent`→`innerHTML` idiom does **not** escape the quote, so it is a *body* encoder and using it for an attribute value is a defect (a `"` in the value breaks out — the `viewer.html` `title`-attribute residual is the worked caveat). **DOM safe-sink discipline:** prefer `textContent` / `createElement` / `Number()` over the raw-HTML sink family (`innerHTML` / `outerHTML` / `insertAdjacentHTML` / the legacy `document.write`/`.writeln`); when a raw-HTML sink is unavoidable, **every** interpolation is context-encoded or type-coerced **and** the node is sanitized (drop `<script>`, strip `on*` handlers, neutralize `javascript:`/`data:`/`vbscript:` on `href`/`src`) before it is connected — a **scheme denylist alone is not a general sanitizer** (the `sheet_to_html`→`innerHTML` residual is the worked caveat). **Placeholder-template rule:** a build-time placeholder resolving **inside** an inline `<script>` MUST be filled by a context-aware encoder, or moved into an inert `<script type="application/json">` block read via `JSON.parse(el.textContent)` (with the filler still neutralizing `<`); a bare `= __PLACEHOLDER__` in executable script context with no committed encoder is a defect. **Sibling-parity rule:** sibling emitters MUST agree on the encoding contract — a divergence where one escapes and its twin does not is the recurrence vector. **Reviewed-baseline convention:** the enforcing lint keys on **missing** context-aware encoding (not on `json.dumps` or `innerHTML` presence — a blunt ban would false-positive the fixed emitter and invite a blanket suppression that reopens the hole); a reviewed-safe sink carries a per-sink `nosemgrep: <rule-id> -- xss-sink-reviewed: <one-line why-safe>` (host-language comment leader), a NEW or un-annotated sink fails, and **blanket file/rule suppression is prohibited**. **Design-consumption note:** a design that emits untrusted data into a markup/transport sink is checked for (a) sink-context-appropriate encoding at every interpolation, (b) no `json.dumps` straight into `<script>` without the `< > &` neutralization, (c) no body-encoder used in an attribute context, and (d) a reviewed per-sink annotation (never a blanket suppression) on any raw-HTML sink retained by construction. **Enforcers:** `core/security/semgrep/rules/template-context-xss.yml` (R1 transport-taint · R2 raw-HTML DOM sink · R3 script-context placeholder) + the `security.yml` `semgrep` job. **Source:** `[PLATFORM: eval-viewer XSS remediation · GHSA-rw36-5pf9-w2vc]`.

- **Injection resistance.** Unresolvable or traversal tokens (shell variables, command substitution, backticks, `..` path components, symlink escapes) are **denied by construction** rather than best-effort-sanitized; the strict-policy branch of `block-fs-boundary.sh` (deny on any token the normalizer cannot resolve to an in-boundary absolute path) is the worked exemplar. **Design-consumption note:** a design that resolves a path or command token from untrusted input is checked for a strict deny on any token it cannot fully resolve, evaluated independent of the optional normalizer (a missing normalizer must not open the gate). **Source:** `[PLATFORM: block-fs-boundary strict policy · GHSA-9cjm-v22x-4x33 V2]`.

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — it tells a Stage-5/7 spoke what to check a software design against. It is distinct from the platform's source-taxonomy, which is the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the taxonomy's software-domain (D4) sources; the taxonomy does not carry an Applicability Profile and does not tell a design what to check. Different objects, clean seam: do not collapse the guide into the source taxonomy or vice versa.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, but with `UNIVERSALITY: contextual` and a narrower context predicate, placed in the operator-instance layer rather than the platform corpus. Authoring this guide to the standard Profile schema **is** what lets a later onboarding capability plug in by emitting the same shape — reusing the existing schema, inventing nothing. A future contextual KB that needed a *different* Profile shape would signal this seam was mis-designed; conformance to the standard schema is therefore load-bearing, not cosmetic.

## Cutover

This guide and the domain-best-practice guide class apply to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — the guide class shipping in a release cannot retroactively bind its own design/review work, which ran before the guide existed. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline carry.

---
pack_name: security
pack_version: "1.0"
applies_to: "Pack-level AppSec/SecOps review of a platform surface — security controls, hooks, CI/CD security jobs, dependency posture, secret exposure, and the code/config that implements them"
detection_patterns:
  - "**/core/security/**"
  - "**/core/hooks/**"
  - "**/.github/workflows/security.yml"
  - "**/*.gitleaks.toml"
default_when_no_match: false
dimension_count: 8
principal_dimensions_included: false
---

# Security — Dimension Pack

Review-time AppSec/SecOps dimensions for a **platform surface** — the security controls, hooks, CI security jobs, dependency posture, secret-exposure surface, and the code and config that implement them. This pack asks whether the controls a surface already carries **hold**; it does not design them.

This pack supplies 8 domain-specific dimensions organized into 3 areas (Control Hygiene, Dependency and Secret Posture, Enforcer Coverage), plus the 3 Principal Dimensions rendered from `build-reviewer/SKILL.md` at every invocation. Shared review discipline lives in `core/disciplines/review-discipline-principles.md` and governs this pack like every other.

**Severity scale:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` per `review-discipline-principles.md` § Section 5. No Copilot-native aliases apply here, and this pack introduces no security-specific severity vocabulary — a security finding is severity-rated on the same scale as any other finding.

**Scope boundary — this pack is review-time, not design-time.** Architecture-level threat modeling, trust-boundary decomposition, control *selection*, security NFRs, and the security architecture decision record belong to the Architect Specialist's security-architecture mode, which reasons inward from adversary goals through trust boundaries to a control set. This pack runs the opposite direction and at a different moment: it takes the controls that already exist in the surface under review and asks whether each one does its job, including on the branch where it cannot. A review that starts decomposing trust boundaries has crossed into that mode's surface and should route there instead of continuing here.

**Sourcing.** Area A is sourced to `core/standards/domain-best-practices/software.md` § Security — its four codified concepts (fail-closed controls, input validation, sink-context output encoding, injection resistance) map one-to-one onto SEC-D1 through SEC-D4, each with a named live enforcer. Areas B and C carry a named `UNSOURCED-DOMAIN` residual: no operational-SecOps domain guide exists in this corpus (vulnerability-management lifecycle, advisory prioritization, disclosure handling), so those dimensions are authored on platform-observable practice rather than an external framework. State that limitation in the review when the depth of an external practice framework would change the answer.

---

## Review Dimensions

You must evaluate the surface against every dimension below. For each dimension, produce findings or provide explicit evidence-of-check per Anti-Laziness Rule 3. Dimensions are organized into three areas (A–C).

**Pack-specific evidence requirement.** Every finding — and every finding-free verdict — in this pack must name the **failure branch** it exercised: what happens when the dependency is missing, the input is malformed, the sink is untrusted, the token is unresolvable, the advisory is unpatched, the scanner is misconfigured. A finding that reads identically whether the control fails open or fails closed has not exercised anything. Enforcer *presence* is greppable; enforcer *efficacy* is not, and this pack grades the second.

---

### Area A — Control Hygiene

The platform's codified software-security concepts, one dimension each. A security control is the discipline of staying safe when the control *cannot do its job*; these four dimensions audit the branch where it cannot.

#### SEC-D1 — Fail-Closed Control Behavior

**What to check:**
- Every security control that shells out to an external tool to evaluate its rule **denies** (`exit 2`) when that tool is unresolvable. A bare `exit 0` or `return 0` on a dependency-missing branch is a defect, not a graceful degradation.
- The deny is evaluated **after** the mode / bypass short-circuit, and the mode read is parser-free (`cat` / `tr`, never the tool being tested for) and placed **before** the dependency gate. The reverse ordering silently disables an always-enforce floor under `enforce`.
- Missing-dependency posture is **mode-coupled**: `enforce` — and an always-enforce control carrying no mode file — fails closed with a dependency-missing signal; `warn` and `off` degrade with a dependency-degraded signal, so a missing dependency never blocks harder than a rule match would.
- Dependency resolution routes through the single shared resolver rather than a per-control re-implementation; the *deny* remains the calling control's invariant, not the resolver's.
- No `exit 0` fall-through past a failed parse, an unset variable, or an un-normalized path on any branch of the control.
- The reviewer reads the actual ordering in the file — mode read, dependency gate, rule evaluation — rather than the posture the control's header comment declares.

**Specific areas of known risk:**
- Controls added since the last fail-closed audit. The behavioral enforcer derives its population from a glob, so a control placed outside that glob is unasserted and a green suite says nothing about it.
- Controls whose mode is read using the very parser whose absence is being tested — a circular dependency that classifies as `off` precisely when the parser is gone.
- Controls correct in the rule-match branch and fail-open only on the dependency branch. That is the branch a presence check never exercises and the class that shipped a real advisory.

**Root-cause requirement:** For any fail-open branch, distinguish three causes and name which: **resolver-bypass** (the control re-implemented dependency lookup instead of calling the shared resolver), **ordering defect** (the dependency gate precedes mode detection), or **posture-not-coupled** (the control denies or degrades uniformly regardless of mode). Then identify the release that introduced the branch and whether the enforcer's population glob covered the control at that time.

#### SEC-D2 — Input Validation and Deny-on-Malformed

**What to check:**
- Every surface consuming untrusted or tool-call input carries an **explicit validity gate** that denies on malformed input rather than proceeding on a best-effort parse.
- The gate's failure path is a deny (`exit 2`), not a continue-with-empty. Extracting a field that comes back empty and then proceeding as though the field were absent is a silent allow wearing a validation check's clothes.
- Field extraction distinguishes *absent* from *empty* from *unparseable* where those cases have different security meanings; a single `// empty` fallback that collapses all three is a finding when any of them should deny.
- Type and range coercion happens before the value reaches a decision — a path, a mode, a boolean, a count is normalized and re-checked, not trusted from the wire.
- Where the control fails open by explicit design (a defensive parse-failure exit), the exemption is **stated in the file with its reason** and is narrow enough that a reviewer can name what it lets through.
- The reviewer supplies at least one concrete malformed input per validated surface and traces what the code does with it, rather than confirming that a validation function is called.

**Specific areas of known risk:**
- Inputs whose schema recently changed — a validator written against the old shape passes structurally and stops constraining the new field.
- Surfaces that validate the *outer* envelope and then trust nested values extracted from it, which is where the untrusted content actually lives.
- Defensive `exit 0` fall-throughs added during debugging and never re-tightened; they read as deliberate because they carry a comment.

**Root-cause requirement:** For a missing or permissive validity gate, distinguish **never-authored** (the surface was added without a gate), **eroded** (a gate existed and a later edit added a permissive branch around it), and **mis-scoped** (a gate exists but validates a different field than the one that reaches the decision). Name which, and identify whether the deficiency is reachable from an untrusted caller or only from an already-trusted one — a validation gap on an unreachable path is a `LOW`, not a `HIGH`.

#### SEC-D3 — Sink-Context Output Encoding

**What to check:**
- Untrusted data is encoded for the **sink context** it lands in — HTML body, inline script, HTML attribute, URL, shell — not merely for transport validity. The same value needs a different transform per context, and encoding for the wrong context leaves the sink injectable.
- **Inline script context:** serialization alone is insufficient. A JSON serializer escapes the double quote but not `<`, `>`, `&`, so a script-closing sequence can still form; the emitter must additionally neutralize those three to escape sequences.
- **Attribute context:** the body-encoder idiom (assigning to a text property and reading back markup) does **not** escape the quote character, so using it for an attribute value is a defect — a quote in the value breaks out. Attributes are always quoted and always attribute-encoded.
- **DOM sinks:** safe sinks are preferred over the raw-HTML sink family. Where a raw-HTML sink is unavoidable, every interpolation is context-encoded or type-coerced **and** the node is sanitized before it is connected. A scheme denylist alone is not a general sanitizer.
- **Sibling parity:** emitters that produce the same artifact agree on the encoding contract. One escaping and its twin not escaping is the recurrence vector, not an inconsistency to note.
- **Reviewed-baseline convention:** a retained raw-HTML sink carries a per-sink reviewed annotation naming why it is safe. A blanket file-level or rule-level suppression is prohibited and is itself a finding.

**Specific areas of known risk:**
- Build-time placeholders that resolve *inside* an inline script — the placeholder is invisible to a source-level review of the template and to a runtime review of the output.
- Emitters added after the last encoding remediation, which inherit the pattern but not the annotation, and therefore read as reviewed when they were never reviewed.
- Any suppression comment whose scope is wider than one sink; it reopens the class it was added to close.

**Root-cause requirement:** For an unencoded or wrongly-encoded sink, name the **context mismatch** precisely (encoded for body, lands in attribute; serialized for transport, lands in script) rather than reporting "output not escaped." Then distinguish **new-sink** (added after the remediation baseline), **parity-drift** (a sibling emitter diverged), and **suppression-erosion** (a reviewed annotation widened into a blanket suppression). Identify whether the detecting lint would have fired and, if not, why its rule did not reach this sink.

#### SEC-D4 — Injection Resistance and Deny-by-Construction

**What to check:**
- Path and command tokens derived from untrusted input are **denied by construction** when they cannot be fully resolved, not best-effort sanitized. Shell variables, command substitution, backticks, parent-directory components, and symlink escapes are token classes to deny, not strings to strip.
- The strict deny is evaluated **independently of the optional normalizer** — a missing or failed normalizer must not open the gate. A normalizer that returns empty and a caller that treats empty as "nothing to check" is the composite defect.
- Path boundary checks compare **normalized absolute** paths, and the normalization itself is failure-checked. A prefix comparison against an unnormalized path is defeated by a parent-directory component.
- Command construction uses argument arrays or explicit quoting throughout; a single unquoted interpolation in an otherwise-quoted command is the whole finding.
- Interpreter and utility invocations resolve to explicit paths or a controlled lookup rather than inheriting an attacker-influenceable search path.
- The reviewer supplies at least one traversal or substitution token per boundary and traces the resolution, rather than confirming a sanitizer exists.

**Specific areas of known risk:**
- Boundary checks that were correct when authored and now run against a path assembled from a new source that the original normalizer never anticipated.
- Allowlist entries expressed as substring matches rather than anchored path prefixes — a substring allowlist matches inside an attacker-chosen path segment.
- Symlink handling, which is the component most often omitted because it does not appear in the token vocabulary the rest of the check enumerates.

**Root-cause requirement:** For each injection surface, distinguish **sanitize-instead-of-deny** (the control transforms a hostile token and proceeds rather than refusing it), **normalizer-coupling** (the deny depends on an optional normalizer that can be absent or fail), and **comparison defect** (the boundary test compares the wrong form of the path). Name which, and state what an attacker reaches when the branch is taken — a finding that cannot name the reachable target is an observation, not a finding.

---

### Area B — Dependency and Secret Posture

The two supply-side exposure surfaces. Both are continuously changing rather than statically authored, so both are graded on the *currency and reachability* of the assessment, not only on the presence of a scanner.

#### SEC-D5 — Dependency and Advisory Reachability

**What to check:**
- Every dependency-bearing surface in the review scope is covered by an advisory scanner, and the scanner's **population is asserted**, not assumed — a manifest outside the scanner's declared paths produces a clean run that means nothing about it.
- Each open advisory is dispositioned as **reachable** or **not reachable**, with the reachability claim traced to an actual call path or entry point rather than to the advisory's own severity score. An unreachable critical and a reachable medium do not rank in severity order.
- Accepted-residual advisories carry a recorded reason, an owner, and a re-check condition. An advisory suppressed with no recorded reason is a finding regardless of its score.
- Transitive dependencies are in scope. A direct-only assessment is incomplete and should be reported as a coverage gap, not as a clean result.
- Pinning and update posture is coherent: pinned versions have an update path, and an unpinned dependency in a security-relevant position is itself a finding.
- Scanner findings are reconciled against the surface's actual runtime — a development-only dependency flagged as production exposure is severity-inflation and fails the shared discipline's severity rule.

**Specific areas of known risk:**
- Dependency subtrees introduced by tooling rather than by application code; they are frequently outside the scanner's declared path set and outside anyone's ownership.
- Advisories that were assessed unreachable at a prior review and became reachable when a new caller was added — the disposition is stale, but the record still reads current.
- A scanner configured non-blocking during a backlog drain and never re-tightened, which reports and never gates.

**Root-cause requirement:** For an unassessed or misassessed advisory, distinguish **out-of-population** (the manifest is not in the scanner's path set), **stale-disposition** (the reachability call was correct once and a later change invalidated it), and **score-substitution** (severity was taken from the advisory rather than derived from reachability in this surface). Name which, and state the baseline the assessment was pinned at — a dependency population is transiently observable and a re-check before reliance is required.

#### SEC-D6 — Secret Exposure and Credential Surface

**What to check:**
- Secret scanning runs on the **change delta** as a blocking gate and over **full history** as an audit, and the review names which of the two produced each verdict. A change-scoped clean result says nothing about history.
- The scanner's rule configuration is reviewed for coverage, not merely for presence: which credential shapes it detects, which paths it excludes, and whether any exclusion covers a path where a credential would plausibly land.
- No credential, token, key, or connection string is committed in any form — including inside a fixture, a test, an example config, or a comment. Test credentials are a finding when they are indistinguishable from real ones at scan time.
- Credentials reach the runtime through the host's secret mechanism, and a missing secret **fails loudly** rather than degrading a control into a no-op. A scan that silently scans nothing is indistinguishable from a passing one.
- Personal data and identity values (operator email, home paths, handles) are treated as an exposure class in their own right on any surface the repository publishes, and the review asserts which gate covers that class on which paths.
- Where a leak is found, the review states that the value must be **rotated**, not merely removed — history and forks retain it — and names the rotation owner.

**Specific areas of known risk:**
- Fixture and test-data directories, which are the most common scanner-exclusion and the most common place a real credential is pasted for convenience.
- Any surface whose gate resolves identity or configuration at run time — an unset input is the failure mode that scans nothing while reporting green.
- Content that reaches a public surface through a channel the repository scan does not cover (issue bodies, pull-request bodies, published artifacts), which is a separate exposure surface with its own population.

**Root-cause requirement:** For an exposed or under-scanned credential, distinguish **excluded-path** (the scanner's config excludes where it landed), **shape-miss** (the credential form is not in the rule set), **fail-open configuration** (the gate degraded to a no-op on missing input), and **out-of-repo surface** (the exposure is on a channel this scan does not cover). Name which, and separately state whether the value was ever pushed — the remediation branches on that fact.

---

### Area C — Enforcer Coverage

The two dimensions that grade the security *system* rather than a security *control*. A control that is correct but unwired, and a wired enforcer that cannot fail, are both invisible to Areas A and B.

#### SEC-D7 — Codified-Value Coverage and Named Gaps

**What to check:**
- The platform's Security value has an enforcing artifact named for every toolkit surface in its coverage matrix, and every cell that reads GAP is reported as a **named finding** rather than passed over as an already-known condition. The charter's own gap-detector is run here as a review dimension.
- Each populated cell is verified to name an artifact that **exists and runs** — a cell citing a retired, renamed, or never-authored enforcer is a phantom enforcer and is more dangerous than an empty cell, because an empty cell is honest.
- A cell marked `thin` is assessed for what the indirect coverage actually reaches; `thin` that in practice reaches nothing is a GAP mislabeled.
- Every security concept codified in the domain best-practice guide maps to at least one enforcer, and every security enforcer maps back to a codified concept. An enforcer with no codified concept behind it is unreviewable; a concept with no enforcer is aspirational.
- Newly-added surfaces are checked against the matrix — a surface that postdates the matrix's last revision has no cell at all, which is a third state distinct from GAP and populated.
- Cell claims are read against the enforcer's own scope, not its name: an enforcer whose population glob excludes half the surface populates the cell only for the half it reaches.

**Specific areas of known risk:**
- Cells populated in the same release that authored the value row — those enforcers are the least exercised and the most likely to have been sized to the row rather than to the risk.
- Surfaces where enforcement is asserted to happen "at the perimeter" rather than on the surface itself; verify the perimeter actually covers it rather than accepting the routing claim.
- A GAP that has been open long enough to read as a permanent property of the matrix rather than as an open item.

**Root-cause requirement:** For each GAP or phantom cell, distinguish **never-scoped** (no enforcer was ever planned for the surface), **planned-and-deferred** (an enforcer is designed but unbuilt), and **decayed** (an enforcer existed and was retired, renamed, or narrowed without the cell being updated). Name which, and state what an attacker or a defect reaches on that surface today in the enforcer's absence — a GAP with no stated consequence is a coverage note, not a finding.

#### SEC-D8 — Security-Gate Wiring and Efficacy

**What to check:**
- Every codified security control has a **wired** enforcer — a CI job or a hook that actually executes on the events that matter — and the review names the trigger, not just the job.
- Each gate's **blocking status** is verified against its intent: a gate that reports but does not block, or that is advisory when the control it enforces is mandatory, is a finding with the same weight as a missing gate.
- Path filters and population globs are checked for reach. A gate filtered to paths that no longer contain the surface it protects passes green forever and is the highest-value finding in this dimension.
- Each gate carries a **positive control** — a self-test, a fixture, or a known-vulnerable input that makes the gate fail — and the review confirms the control is exercised in the same run as the gate. A gate with no failing arm cannot be shown to work.
- Warn-mode and shakedown postures are checked for an **exit condition**: which threshold flips the gate to enforce, who owns the flip, and whether the flip has been deferred past its stated trigger. Indefinite warn-mode is enforcement theater.
- Bypass and override mechanisms are enumerated with who can invoke them and whether the invocation is logged. An unlogged bypass is an unreviewable one.

**Specific areas of known risk:**
- Gates whose scan surface moved during a reorganization; the workflow still runs, the filter no longer matches, and nothing reports an error because zero files scanned is a pass.
- Required-versus-optional status drift, where a gate is treated as blocking by its authors and is not in the protection rule set.
- Gates that consume a resolved configuration input; when the input is unset, the gate must fail loudly rather than scan an empty population.

**Root-cause requirement:** For an unwired, non-blocking, or unreachable gate, distinguish **never-wired** (the control shipped without an enforcer), **filter-drift** (the enforcer exists but its path filter or glob no longer reaches the surface), **posture-stall** (the gate is in a warn-mode whose flip condition has passed), and **status-drift** (the gate is not in the required set the authors assume). Name which, and state whether the gate has ever failed — a gate that has never produced a red result over a meaningful window is unproven, not clean.

---

## Pack-Specific Calibration Context

This pack targets a surface whose operator is simultaneously its author, its reviewer, and its only remediator. That collapses two review economics at once. Noise cost is low — a finding lands as a tracked work item or as a remediation commit in the next release — but **self-review bias is the dominant risk**, because the reviewer already knows what each control was intended to do and will read intent into a branch that does not implement it. Every dimension in this pack therefore demands the failure branch be exercised rather than the control's purpose be recalled.

Security findings differ from other findings in one operational respect the reviewer must carry: **a finding here may describe a live exposure**, not a latent quality defect. Where a finding names a credential, a reachable advisory, or a control that fails open on a published surface, the review states the exposure plainly, names the remediation as fix-forward rather than accept-as-residual, and does not soften severity to match remediation appetite. Conversely, severity inflation is equally disqualifying: an unreachable advisory and an unenforceable bypass are `LOW`, and rating them higher spends the operator's attention where no exposure exists.

The deployment target is a repository that publishes. That widens the exposure surface past the working tree to anything the repository or its issue tracker makes visible, and it makes history — not just current state — part of the assessed population.

---

## Pack Start

Start the review with the dimensions where a defect is both most likely and least visible: **SEC-D1** (fail-closed behavior — the branch presence checks never exercise), **SEC-D8** (gate wiring — a green gate scanning zero files is the highest-value finding this pack produces), and **SEC-D6** (secret exposure — the one dimension whose findings may be live rather than latent). Area C is the highest-leverage area, because a defect there invalidates the evidence Areas A and B are read against: if a gate does not reach a surface, every clean result about that surface is a population artifact rather than a verdict.

Before rendering any dimension finding-free, confirm the population it was assessed over and state the denominator. A clean verdict whose scope excluded the surface in question is the failure this pack exists to catch, not a result. After pack-specific dimensions complete, the skill's `## Principal Dimensions` section applies to every finding register regardless of pack.

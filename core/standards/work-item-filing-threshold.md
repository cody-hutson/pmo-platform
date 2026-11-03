---
title: Work-Item Filing Threshold
purpose: The single rule that decides whether a deferred item, a follow-up or an automatically detected signal becomes a new work item — two limbs, how each is read, where an item that fails lands, and what is not filed even when it passes. The release pipeline and automatic intake logging both apply it; each cites this file and restates none of it.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: release/references/standards/finding-disposition-framework.md § 8 (the release pipeline's routing of its follow-ups, and every stage that cites it); operations/skills/intake-desk/SKILL.md § Mode C (automatic intake logging); core/governance/OPERATIONS.md § Continuous Improvement Protocol (the skills' auto-logging duty)
composes_with: work-item-authoring-standard.md (how an item that passes is written); gate-efficacy-standard.md (the register rows that measure this rule's consumers)
domain: governance
---

# Work-Item Filing Threshold

A work item costs whoever triages it, whether or not it is worth doing. This standard decides one question before any item is authored: **is this worth a work item at all?** It is the rule's single home. The release pipeline and automatic intake logging both apply it; each cites this file and restates none of it.

It does not decide how a passing item is written — that is `work-item-authoring-standard.md` — or when a finding is addressed inside a release, which is the release pipeline's finding-disposition framework.

## 1. The rule — two limbs

An item becomes a work item only when it passes **both** limbs:

| Limb | Passes when |
|---|---|
| **Class** | the item is **user-visible**, **security-relevant**, or **privacy-relevant** |
| **Severity** | the item reads **at least Minor** on the five-bucket finding scale — Blocker / Major / Minor / Cosmetic / Informational |

An item that fails either limb is **below the threshold**. An item that cannot be read on a limb is below the threshold, with the reason recorded. Being well-formed and unowned is never, by itself, a reason to file.

## 2. What user-visible means for a platform-internal item

For an item about the platform itself — its pipeline, its skills, its records — the operator's ruling of 2026-10-24 decides the class limb: the item is user-visible when a user of the platform is **blocked**, or **misled into a wrong action**, observed or plausible. Two of the platform's own records disagreeing, where no user acts on the disagreement, is not user-visible.

## 3. Reading the severity limb

The scale's definitions are the release pipeline's finding severity vocabulary (`release/references/pipeline/stage-07-dev-testing.md`, the severity vocabulary reconciliation). Other sources read onto it here:

| Source | Reads as |
|---|---|
| a severity declared on the five-bucket scale | itself |
| this platform's `bug.yml` Severity field | P1 → Blocker · P2 → Major · P3 → Minor · P4 → Cosmetic |
| a severity on another repository's own scale | read by that scale's own descriptions at the time of reading, the reading recorded beside the verdict |
| no declared severity | read from the item's content, the reading recorded beside the verdict |

**Who reads it, and when.** Class and severity are read by whoever surfaces the item, when it is surfaced, and every later step carries that reading unchanged. A later step that reads the item differently records its reading and the reason beside the original; it never overwrites it.

## 4. Below the threshold

A below-threshold item is recorded where it surfaced — in the record of the step or session that found it — with its verdict, and is **filed nowhere**. Each consumer names that record for its own surface (§ 7).

## 5. What is not filed even when it passes

- **Already declared.** Before an item is filed, search the ADRs (`core/ADRs/`, `release/ADRs/`), `CHANGELOG.md`, and the decision records of the work that surfaced it. An item one of them already declares — as a residual, a consequence, or an accepted deviation — is not filed again; the citation is recorded in its place. **A record declares an item only when it accepts it.** A record that defers an item declares nothing: the deferral is the item being routed, and it goes on through this standard.
- **Owned.** An item whose work an open work item already owns folds into that item instead of becoming a new one. The search for an owner is the charter's pre-creation governance check, cited here and not restated.

## 6. A security-relevant item

A security-relevant item whose description would disclose an exploitable weakness is never described in a public record. Its row reads `security — description withheld` with a pointer the operator can follow privately, and public counts include it without describing it. The operator reports it through the security policy of the repository it concerns — for this platform, `SECURITY.md`, a private advisory. No agent files it.

## 7. Consumers

| Consumer | Where a below-threshold item lands | How a passing item is filed |
|---|---|---|
| The release pipeline | the stage record that surfaced it | `release/references/standards/finding-disposition-framework.md` § 8 |
| Automatic intake logging (`intake-desk` Mode C) | the held record Mode C returns to its caller, noted in the caller's own output | through Mode C's `automation_level` clamp, or held for a release's sweep when the caller names the run |

Each consumer carries its own cutover; this standard states none.

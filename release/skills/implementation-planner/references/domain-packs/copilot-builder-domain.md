---
pack_name: copilot-builder
pack_version: 1.0
applies_to: "Copilot Builder Agent Document Pack (30 production files + 1 derived artifact Runtime_Constitutional_Minimum_Set.md)"
detection_patterns:
  - "**/Copilot_Builder_Agent_Document_Pack/**"
  - "**/Doc_0[1-9]_*.md"
  - "**/Doc_[12][0-9]_*.md"
  - "**/Doc_30_*.md"
  - "**/Runtime_Constitutional_Minimum_Set.md"
default_when_no_match: false
rt_types_supported: [RT-1, RT-2, RT-3, RT-4, RT-5, RT-6, RT-7, RT-8]
operator_profile_default: "Senior Technical Program Manager with deep familiarity with the document pack architecture. Built this framework; been through every remediation round."
severity_scale_native: "CS1..CS4"
sequencing_rules_ref: "#constitutional-first-sequencing"
batch_limits: { max_records: 5, max_files: 3 }
principal_dimensions_included: false
---

# Implementation-Planner — Copilot Builder Domain Pack (v1.0)

This pack parameterizes `implementation-planner` for the Copilot Builder Agent Document Pack. It is the original and most-exercised domain — 30 production files (Doc_01 through Doc_30) plus the derived `Runtime_Constitutional_Minimum_Set.md`. Backward-compatible with all prior Copilot remediation rounds: output shape for RT-1..RT-5 is semantically identical; only the rendering format has changed (Edit-ready per [`../output-format-spec.md`](../output-format-spec.md)).

**Registry:** [`README.md`](README.md) — pack schema, domain-detection rules, fallback-banner spec.

---

## Pack Input Expectations

Input: findings register from `build-reviewer` invoked with `--pack=copilot-builder`. Register format:

- Each finding: `Finding-ID`, `Dimension` (per Copilot's 12-dimension taxonomy), `Severity` (CS1..CS4 — see Severity Scale Native below), `Affected Documents` (Doc_NN references), `Root Cause` (with review-discipline-principles.md Section 2 "systemic pattern → proximal cause → observable signal" chain), `Evidence` (source-file citations), `Risk if Unresolved`, `Recommended Resolution`, `Resolution Complexity`.
- Register may also include Residual Risks carried from prior rounds (CFR-NNN references per Doc 28).

Findings with severity `CS1_LOW` are eligible for RT-8 accepted-residual if the Resolution Complexity ratio justifies acceptance over fix.

---

## Severity Scale Native (CS1..CS4)

The Copilot pack uses a 4-tier numeric severity scale established in Doc_07. The planner emits both the native CS token AND the normalized CRITICAL..LOW equivalent per `SKILL.md § Severity Normalization`.

| CS token | Normalized | Meaning (per Doc_07) |
|---|---|---|
| `CS4_CRITICAL` | CRITICAL | Would cause production failure or governance breach if unresolved |
| `CS3_HIGH` | HIGH | Materially degrades correctness, reliability, or integrity |
| `CS2_MEDIUM` | MEDIUM | Noticeable defect with a workaround |
| `CS1_LOW` | LOW | Cosmetic, stylistic, or low-impact drift |

Implementation Record Metadata convention: `Severity (validated): CS3_HIGH [HIGH]` — native token first, normalized token in brackets, preserved for Doc 28 residual-register format compatibility.

---

## #constitutional-first-sequencing (Sequencing Rules)

These rules govern batch ordering within a Copilot-pack invocation. Load-order: the planner consults this section when building the Execution Batch Plan.

1. **Constitutional fixes first.** Changes to Docs 01-04 that affect downstream interpretation must be applied before any downstream fix that depends on them. Docs 01-04 = Constitutional Core (Doc_01 Constitution, Doc_02 Operating System, Doc_03 Layered Governance, Doc_04 Taxonomy).
2. **Schema fixes before consumer fixes.** If Doc_09 (Contracts) needs a field correction, apply that before correcting references in Docs 11-15 that consume that field.
3. **Enum and vocabulary fixes before semantic fixes.** Normalize controlled vocabulary before fixing logic that depends on that vocabulary.
4. **Independent fixes parallelize.** If two findings affect unrelated documents with no shared dependency, they can be in the same batch.
5. **Extract regeneration (RT-6) is always last before manifest.** `Runtime_Constitutional_Minimum_Set.md` is regenerated only after all upstream changes to Docs 02, 03, 04, and 07 are complete.
6. **Manifest update (RT-7) is always final.** Doc 28 checksums are recomputed only after all file changes (including RT-6 extract) are complete.

---

## RT-6 Extract Specifics (Copilot)

**Trigger condition:** Any change to Docs 02, 03, 04, or 07 that affects sections included in `Runtime_Constitutional_Minimum_Set.md`.

**Target artifact:** `Runtime_Constitutional_Minimum_Set.md` — derived artifact assembled from constitutional core sections. Source sections per Doc_02 extraction spec.

**Co-load guard check:** Doc 11 default separate-load behavior must be preserved. RT-6 regeneration must NOT modify Doc 11's default assumption that Doc 02/03/04 are loaded separately at runtime; the extract is a convenience for agents that need the constitutional minimum in a single context window, not a replacement for the full docs.

**Expected checksum impact:** Doc 28 Section "Runtime Extract Checksums" row for `Runtime_Constitutional_Minimum_Set.md` — always changes when RT-6 fires. Doc 28 rows for the source Docs (02, 03, 04, 07) also change if those Docs were edited in the same release.

**Edit-ready bash fragment (consumed by output-format-spec.md RT-6 template):**

```bash
# Regenerate Runtime_Constitutional_Minimum_Set.md from source Docs 02/03/04/07
# Actual extraction logic is encoded in Doc_02's derivation spec — this fragment
# is a placeholder for the operator-supplied regeneration script.
python3 scripts/regenerate_runtime_extract.py \
  --sources Doc_02_Operating_System.md Doc_03_Layered_Governance.md Doc_04_Taxonomy.md Doc_07_Severity.md \
  --output Runtime_Constitutional_Minimum_Set.md \
  --preserve-doc11-separate-load-default
# Verify co-load guard preserved:
grep -q "separate load default" Doc_11_*.md || { echo "CO-LOAD GUARD REGRESSION" >&2; exit 1; }
```

Operators executing this RT-6 must substitute their pack's actual regeneration script in place of the `python3 scripts/...` line.

---

## RT-7 Manifest Specifics (Copilot)

**Trigger condition:** Any change to any file in the pack (including RT-6 extract regeneration).

**Target artifact:** Doc 28 — `Manifest_and_Risk_Register.md`. Fields affected: (a) Inventory checksums (per-file sha256), (b) Residual Risk Register rows (for any RT-8 accepted residuals from this round), (c) Version-log rollup.

**Edit-ready bash fragment (consumed by output-format-spec.md RT-7 template):**

```bash
# Compute sha256 checksums for all touched files in this release
for f in Doc_01_*.md Doc_02_*.md Doc_03_*.md Doc_04_*.md Doc_07_*.md Runtime_Constitutional_Minimum_Set.md; do
  [[ -f "$f" ]] && sha256sum "$f" | awk '{print $1 "  " $2}'
done
# Output consumed by operator; copy-paste the new sha256 values into Doc 28's inventory section
# for the rows whose underlying file changed in this release.
```

The file list above is illustrative; the planner populates it per release-specific touched-files inventory.

---

## Calibration Context (Copilot)

The person executing a Copilot-pack plan is a Senior Technical Program Manager with deep familiarity with the document pack architecture. They built this framework and have been through every remediation round. They do not need explanations of what the documents are or how the framework works. They need precise edit specifications they can execute quickly with confidence that each edit closes exactly one finding without creating new issues.

The primary concern is not speed of execution — it is precision and non-regression. A remediation plan that takes twice as long to execute but introduces zero new defects is vastly preferable to a fast plan that creates cascading issues.

This pack has been through ~8 prior remediation rounds. The single greatest risk at this stage is not missing fixes — it is over-correction that destabilizes working controls. The pack's Minimal-Change Remediation Bias (per `SKILL.md § Your Governing Constraint`) is load-bearing: smallest viable fix first, preserve working structure, no unnecessary cascade, no invented new controls, no fix what isn't broken.

---

## Pack Version Log

- **v1.0 (2026-04-19):** Initial extraction from `implementation-planner/SKILL.md` inline content per the pluggable-domain refactor. RT-1..RT-8 taxonomy retained verbatim; Copilot-specific content (Doc references, RT-6 extract target, RT-7 manifest target, Senior-TPM operator profile, constitutional-first sequencing rules, CS1..CS4 severity scale) moved here.

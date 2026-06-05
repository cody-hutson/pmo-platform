# Compliance Rules — PMO Communications

## Purpose

This file defines the compliance rules applied to all PMO communications before
send. The comms-writer skill reads this file during the readiness check (Section 4
of output format) and validates each draft against these rules. Compliance failures
block READY FOR SEND status.

---

## 1. Communication Compliance Checklist

Every communication draft is validated against this checklist. A failure on any
Critical item blocks READY FOR SEND status. Warning items are flagged but do not
block.

| # | Check | Severity | What to Verify | Failure Action |
|---|-------|----------|---------------|---------------|
| CC-01 | **Factual accuracy** | Critical | All dates, statuses, owners, and decisions are traceable to source artifacts. No fabricated data. | Mark NOT READY; list each unverified claim with source needed |
| CC-02 | **Evidence tagging** | Critical | Every factual claim has an evidence quality label: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION - CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]` in working notes. Unresolved `[ASSUMPTION - CONFIRM]` tags on material claims block readiness. | Mark NOT READY if material assumptions remain unconfirmed |
| CC-03 | **No internal IDs in external output** | Critical | Strip MTG-##, MSG-##, TR-###, RAID prefixes, IMP-### from all communications to stakeholders. Use descriptive names. Internal IDs are for PMO cross-referencing only. | Remove IDs; replace with descriptive references |
| CC-04 | **Date validation** | Critical | All date references include validated day-of-week. Dates verified against PROJECT.md or carry-forward tracker. No generalized dates (e.g., "week of April 6" when a specific date is known). | Verify against authoritative source; surface conflicts rather than generalizing |
| CC-05 | **Recipient completeness** | Critical | To, CC, BCC fields populated with rationale for each recipient. No orphan communications (sent without clear audience). | Add missing recipients with rationale |
| CC-06 | **Action item completeness** | Critical | Every action item has: owner (named person, not role), deadline (specific date), and deliverable (what they produce). No orphan action items. | Complete missing fields or mark NOT READY |
| CC-07 | **Tone match** | Warning | Tone matches audience tier per voice-guide.md Tone Calibration Matrix. No casual tone for executive, no formal structure for Teams. | Adjust tone; note adjustment in audience notes |
| CC-08 | **Active voice** | Warning | Active voice used per voice-guide.md requirements. Passive voice only where deliberately chosen for political sensitivity (noted in working notes). | Rewrite passive constructions |
| CC-09 | **Plain language** | Warning | Technical jargon translated for non-technical audiences per voice-guide.md Plain Language Guidelines. | Replace jargon or define on first use |
| CC-10 | **Methodology vocabulary** | Warning | Vocabulary matches audience's methodology context per voice-guide.md Methodology-Aware Language Rules. No Agile jargon to Waterfall stakeholders or vice versa. | Reframe using audience-appropriate terms |
| CC-11 | **Brand alignment** | Warning | Communication represents the PMO and TPM voice consistently. No conflicting tone or positioning across simultaneous communications about the same topic. | Align with established voice patterns |
| CC-12 | **Vendor label consistency** | Warning | Vendor/consultant affiliation labels applied consistently across all named individuals from the same organization. | Standardize labels across all names |
| CC-13 | **No template residue** | Critical | No `[INSERT]`, `[TBD]`, `[ADD DETAILS]`, or generic placeholders. Every gap is a named, specific information need. | Replace with specific gap description or resolve |
| CC-14 | **Recommended date marking** | Critical | Agent-recommended deadlines not sourced from a project artifact are labeled `[RECOMMENDED]` to distinguish from committed dates. | Add `[RECOMMENDED]` label |
| CC-15 | **Memory attribution labeling** | Warning | Names, roles, or ownership sourced from project memory rather than current artifact are labeled `[CONTEXT]` with note "from project context, not current artifact." | Add `[CONTEXT]` label with attribution note |
| CC-16 | **Accessibility** | Warning | Tables have headers. Color is not the sole information carrier (RAG includes text labels). Links have descriptive text (not "click here"). | Add accessibility affordances |

### Compliance Score

| Result | Criteria | Status |
|--------|----------|--------|
| **PASS** | Zero Critical failures, zero or more Warning flags noted | READY FOR SEND |
| **CONDITIONAL** | Zero Critical failures, 3+ Warning flags | READY FOR SEND with noted flags |
| **FAIL** | Any Critical failure | NOT READY — list each failure with remediation |

---

## 2. Approval Routing Rules

Not all communications require pre-send approval. Routing depends on communication
type, audience, and content sensitivity.

| Communication Type | Audience | Approval Required | Approver | Rationale |
|-------------------|----------|------------------|----------|-----------|
| Executive brief / SteerCo package | VP+, Sponsor, Steering Committee | Yes — content review | TPM (self-review + stakeholder alignment check) | Exec communications set expectations; errors are high-cost |
| Escalation communication | Any escalation target | Yes — tone and framing review | TPM reviews; may require sponsor pre-brief | Escalations create organizational memory; framing matters |
| Go-live announcement | Org-wide | Yes — content + timing review | TPM + sponsor approval | Go-live communications are baselined; retraction is damaging |
| Policy change communication | Affected stakeholder groups | Yes — content + legal/compliance review | TPM + policy owner | Policy communications create obligations |
| Vendor communication | External vendor/consultant | Yes — contractual awareness review | TPM; legal review if contractual implications | External communications have contractual and legal implications |
| Project team status update | Project team, PM peers, tech leads | No — TPM direct send | N/A | Operational communications within established cadence |
| Meeting recap | Meeting attendees | No — TPM direct send | N/A | Factual record of what occurred; low risk |
| Meeting agenda | Meeting attendees | No — TPM direct send | N/A | Pre-meeting coordination; low risk |
| Teams message | Internal team | No — TPM direct send | N/A | Informal coordination; low risk |
| Confluence update | Reference audience | No — TPM direct send (unless baselined content) | TPM for baselined content updates | Baselined content updates require version control discipline |

### Pre-Brief Protocol

For high-stakes communications (escalations to VP+, go/no-go recommendations,
budget impact notifications), the TPM may pre-brief the recipient verbally before
sending the written communication. The pre-brief ensures no surprises in the
written record.

**Pre-brief decision rule:** If the recipient would be surprised or upset by the
written communication, pre-brief first. If the communication confirms what the
recipient already knows or expects, send directly.

---

## 3. Sensitive Information Handling

Different channels have different security profiles. Information classification
determines what can appear where.

| Information Type | Email | Teams Message | Teams Channel | Confluence | Presentation |
|-----------------|-------|---------------|---------------|------------|-------------|
| **Project status** (RAG, milestones, timelines) | Yes | Yes | Yes (project channels) | Yes | Yes |
| **Budget figures** (specific dollar amounts) | Yes (internal only) | Yes (DM only) | No | Yes (access-controlled) | Yes (internal audience only) |
| **Personnel issues** (performance, HR matters) | Yes (restricted To: only) | Yes (DM only) | No | No | No |
| **Vendor pricing / contract terms** | Yes (internal only, no CC to vendor) | No | No | Yes (access-controlled) | Yes (internal audience only) |
| **Strategic decisions not yet announced** | Yes (restricted distribution) | Yes (DM only) | No | No (until announced) | Yes (restricted audience) |
| **Risk details with business impact** | Yes | Yes (project channels) | Yes (project channels) | Yes | Yes (audience-appropriate) |
| **Security vulnerabilities** | Yes (restricted, encrypted if available) | No | No | No | No |
| **Personal data (PII)** | Yes (restricted, per data privacy policy) | No | No | No | No |

### Channel-Specific Rules

- **Email to external recipients:** Never include internal budget figures, HR
  matters, vendor pricing from other vendors, or strategic decisions not yet
  publicly communicated. When uncertain, default to restricted.
- **Teams channels:** Assume anything posted to a Teams channel may be read by
  anyone with channel access. Never post content that requires restricted
  distribution to a channel.
- **Confluence:** Access controls must match content sensitivity. Budget details
  and strategic plans require page-level access restrictions, not just space-level.
- **Forward risk:** Before sending any communication, consider: "If this were
  forwarded to someone not on the recipient list, would that cause harm?" If yes,
  add a distribution notice: "This communication is intended for the named
  recipients only. Please do not forward without sender approval."

---

## 4. Audit Trail Requirements

Communications that create organizational decisions, commitments, or obligations
must be preserved as audit trail artifacts.

### What Must Be Preserved

| Communication Type | Retention Requirement | Storage Location | Lifecycle Pattern |
|-------------------|-----------------------|-----------------|-------------------|
| Go/No-Go decisions | Permanent (project lifecycle + 2 years) | Email + Confluence | Point-in-time snapshot (immutable) |
| Escalation communications | Project lifecycle + 1 year | Email archive | Point-in-time snapshot |
| SteerCo packages and minutes | Project lifecycle + 2 years | Confluence + email distribution | Point-in-time snapshot |
| Change request communications | Project lifecycle + 2 years | Email + change management tool | Point-in-time snapshot |
| Vendor communications (contractual) | Contract term + retention period | Email archive | Point-in-time snapshot |
| Go-live announcements | Permanent | Email + Confluence | Baselined document (versioned) |
| Status reports | Project lifecycle | Email archive or status reporting tool | Point-in-time snapshot |
| Meeting recaps with decisions | Project lifecycle + 1 year | Email archive | Point-in-time snapshot |

### Audit Trail Integrity Rules

1. **No retroactive editing.** Point-in-time snapshots (status reports, escalation
   emails, go/no-go decisions) are never modified after send. Corrections are
   issued as new communications referencing the original.
2. **Decision attribution.** Every decision captured in a communication must
   attribute the decision-maker by name and date. "It was decided" is insufficient.
   "[COLLEAGUE_A] approved on 3/28" is the standard.
3. **Version control for baselined communications.** Go-live announcements, policy
   changes, and other baselined communications use semantic versioning:
   - Major: fundamental change (new go-live date, policy reversal)
   - Minor: clarification, non-material update
   - Patch: typo, formatting only
4. **Traceability.** Communications that reference project artifacts (RAID entries,
   milestone dates, test results) must cite the source artifact and its version/date.
   Readers must be able to verify the claim against the source.

---

## 5. Version Control for Baselined Communications

Certain communications become baselined artifacts once sent. Modifications to
these communications require formal versioning.

### Baselined Communication Types

| Type | Baseline Trigger | Version Control Method |
|------|-----------------|----------------------|
| **Go-live announcement** | First send to org-wide audience | Semantic version in subject line: "[GO-LIVE UPDATE v1.1] [PROJECT_KEY] System Launch" |
| **Policy change notification** | First send to affected stakeholders | Version number in document header |
| **Training schedule** | First publication | Version note in Confluence page; email update references prior version |
| **Cutover plan communication** | First distribution to cutover team | Version in document header; change log at bottom |
| **Vendor deliverable schedule** | First contractual communication | Version in email subject; change log in body |

### Modification Protocol

1. Create new version (never overwrite the original).
2. Document what changed, why, and who authorized the change.
3. Distribute updated version with explicit callout of changes: "Updated from v1.0:
   go-live date moved from April 10 to April 12 per SteerCo decision on 3/28."
4. Archive prior version with "Superseded by v[X.Y]" notation.

---

## 6. Regulatory and Data Classification Alignment

When the project operates within a regulated environment (SOX, HIPAA, FDA, etc.),
additional compliance rules apply to communications.

### Regulatory Communication Rules

| Regulation | Impact on Communications | Additional Requirements |
|-----------|------------------------|------------------------|
| **SOX** | Financial data in status reports must be accurate and auditable | CFO/Controller review for any communication containing financial projections or actuals |
| **HIPAA** | PHI cannot appear in standard communications | PHI scrubbed from all non-clinical communications; encrypted channel required for PHI transmission |
| **GDPR** | Personal data of EU stakeholders subject to data protection | Consent for stakeholder data in communications; right to erasure applies to stakeholder registers |
| **PCI-DSS** | Cardholder data environment communications | No CHD in email or Teams; restricted Confluence with access audit |
| **Industry-specific** | Varies | Consult compliance officer; document requirements in project RAID log |

### Data Classification Alignment

Map communication content to the organization's data classification scheme. When
no formal classification exists, apply these defaults:

| Classification | Description | Handling Rule |
|---------------|-------------|---------------|
| **Public** | Information intended for or safe for external audiences | No restrictions on channel or distribution |
| **Internal** | Business information for employee use | Standard internal channels; no external distribution without review |
| **Confidential** | Sensitive business information with restricted access | Named recipients only; no channel posts; access-controlled Confluence; distribution notice |
| **Restricted** | Highly sensitive (HR, legal, security, strategic) | Encrypted email or secure channel; no Teams; no Confluence unless isolated; explicit need-to-know |

**Default rule:** When classification is uncertain, default to one level higher
than your best estimate. It is easier to declassify than to recall a misclassified
communication.

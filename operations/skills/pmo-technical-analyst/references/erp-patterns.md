# ERP Patterns — PMO Reference

## Purpose

This file provides the ERP implementation pattern library for the pmo-technical-analyst
skill. It covers ERP-specific execution patterns, risk patterns, go-live strategies,
and cutover planning. Content extends the general enterprise deployment patterns from
the KB with ERP-domain-specific knowledge.

**KB Coverage Note:** Core deployment strategies and go-live criteria are KB-sourced
(C04, C14, C09). ERP-specific patterns (data migration phases, configuration vs.
customization decision framework, cutover checklist) extend beyond KB coverage and
are labeled [EXTENDED] where applicable.

---

## ERP Implementation Pattern Library

### Pattern 1: Data Migration

**Risk Profile:** Highest risk in most ERP implementations; data quality issues are
the #1 cause of ERP go-live failures. [EXTENDED]

| Phase | Activities | Key Risk | Mitigation |
|-------|-----------|----------|------------|
| **Discovery** | Identify source systems; inventory data entities; assess data quality | Unknown data sources; undocumented transformations | Data source inventory audit; stakeholder interviews for tribal knowledge |
| **Profiling** | Profile source data quality (completeness, accuracy, consistency, timeliness); quantify gaps | Data quality worse than assumed; volume exceeds expectations | Automated profiling tools; statistical sampling for large datasets |
| **Mapping** | Define field-level mapping from source to target; document transformation rules; identify default values | Mapping gaps; incompatible data models; many-to-one/one-to-many relationships | Mapping workshops with SMEs; prototype transformations early |
| **Cleansing** | Execute cleansing rules; resolve duplicates; standardize formats; enrich missing data | Cleansing scope larger than estimated; business rules unclear | Start cleansing early (parallel to configuration); prioritize by business impact |
| **Migration Development** | Build ETL/migration scripts; develop reconciliation logic; create rollback procedures | Script errors; performance at volume; reconciliation gaps | Iterative development with mock runs; performance testing with production-volume data |
| **Mock Migration** | Execute full migration in non-production; validate data accuracy; measure elapsed time | Mock reveals new issues; elapsed time exceeds cutover window | Minimum 3 mock migrations before go-live [EXTENDED]; issues feed back to cleansing/development |
| **Production Migration** | Execute production migration during cutover window; reconcile; validate | Errors during production run; reconciliation failures; time overrun | Pre-tested scripts; automated reconciliation; go/no-go decision points during migration |

**Reconciliation framework:** [EXTENDED]
- **Record count reconciliation:** Source count = Target count (per entity)
- **Financial reconciliation:** Source balances = Target balances (for financial entities)
- **Referential integrity:** All foreign key relationships intact post-migration
- **Business rule validation:** Migrated data passes target system business rules
- **User acceptance validation:** Business users verify representative sample

### Pattern 2: Integration

**Risk Profile:** Integration points multiply risk combinatorially. N systems create
N x (N-1)/2 potential integration interfaces. [SOURCE: C04 Anti-Patterns]

| Pattern | Mechanism | When to Use | Risk |
|---------|-----------|-------------|------|
| **Point-to-point** | Direct system-to-system connection | 2-3 systems; simple data exchange; low change frequency | Combinatorial complexity as systems grow; tightly coupled |
| **Hub-and-spoke** | Central integration platform (middleware/iPaaS) | 4+ systems; centralized governance needed | Single point of failure; middleware becomes bottleneck |
| **Event-driven** | Publish-subscribe via message broker | Real-time needs; loosely coupled systems; high volume | Message ordering; eventual consistency; debugging complexity |
| **API-led** | Layered API architecture (system, process, experience) | Modern architectures; reusable integration assets | API governance overhead; versioning discipline required |
| **Batch/file** | Scheduled file transfer (SFTP, blob storage) | Legacy systems; large data volumes; non-real-time acceptable | Latency; error handling; reconciliation complexity |

**Integration testing strategy:** [SOURCE: C09, C14]
- Test each integration point independently before combined testing
- Use contract testing to validate interface compliance
- Performance test at 2x expected peak volume
- Include failure scenario testing (timeout, malformed data, system unavailable)
- Establish monitoring and alerting for each integration point before go-live

### Pattern 3: Configuration vs. Customization

**Decision Framework:** [EXTENDED]

| Dimension | Configuration (Preferred) | Customization (Use Sparingly) |
|-----------|--------------------------|-------------------------------|
| **Definition** | Using built-in system parameters, settings, and options to achieve desired behavior | Writing custom code, modifying base code, or creating custom objects to extend system behavior |
| **Upgrade impact** | Preserved during upgrades; vendor-supported | May break during upgrades; requires regression testing; vendor support limited |
| **Maintenance cost** | Low; handled by functional team | High; requires developers; ongoing maintenance obligation |
| **Time to implement** | Fast (configuration) | Slow (development + testing + deployment) |
| **Decision criteria** | Use when: the standard feature meets 80%+ of the requirement; gap is cosmetic or workflow preference | Use when: the requirement is business-critical AND no standard feature exists AND the gap cannot be bridged by process change |

**Customization governance rules:** [EXTENDED]
1. Every customization requires a business justification documenting why configuration is insufficient
2. Every customization includes an upgrade impact assessment
3. Customizations are cataloged with owners, dependencies, and test coverage
4. Customization-to-configuration ratio is tracked as a health metric (target: <20% customization by feature count)
5. "Fit-to-standard" workshops challenge customization requests before approval

### Pattern 4: Reporting and Analytics

| Approach | Mechanism | When to Use | ERP-Specific Consideration |
|----------|-----------|-------------|---------------------------|
| **Embedded reporting** | Built-in ERP reporting engine | Standard reports; real-time data needs | Limited customization; may not meet complex analytical needs |
| **Data warehouse** | ETL to separate analytical database | Complex analytics; cross-system reporting; historical analysis | Latency between ERP and warehouse; reconciliation needed |
| **Real-time dashboards** | Direct connection to ERP operational data | Operational monitoring; simple KPIs | Performance impact on ERP; read-only connections recommended |
| **Self-service BI** | BI tool (Power BI, Tableau) connected to ERP/warehouse | Ad-hoc analysis; business user empowerment | Data security model must mirror ERP permissions [EXTENDED] |

---

## ERP-Specific Risk Patterns

| Risk Category | Common Manifestation | Early Warning Signal | Mitigation |
|--------------|---------------------|---------------------|------------|
| **Data migration integrity** | Migrated data fails business rules; financial reconciliation discrepancies; orphaned records | Mock migration defect count not decreasing between runs; reconciliation gaps growing | Additional mock migrations; dedicated data quality team; reconciliation automation |
| **Integration point failures** | Timeout errors under load; data format mismatches; message loss | Integration test failures trending up; monitoring alerts increasing in staging | Contract testing; load testing at 2x peak; circuit breaker patterns; dead letter queues |
| **Customization debt** | Upgrade blocked by custom code; regression failures after patches; developer dependency for routine changes | Customization count growing; upgrade assessment reveals breaking changes; developers needed for configuration-level tasks | Fit-to-standard reviews; customization catalog; refactor toward configuration |
| **Performance at scale** | System slow with production data volume; batch jobs exceed overnight window; concurrent user capacity exceeded | Performance degradation trend in staging; batch job duration growing with data volume | Performance testing with production-volume data; database optimization; architecture review |
| **User adoption failure** | Low system usage post-go-live; workarounds in spreadsheets; shadow IT proliferation | Training attendance low; UAT participation low; change resistance signals in stakeholder feedback | Early user involvement; hands-on training (not just documentation); champion network; post-go-live support [EXTENDED] |
| **Scope creep via requirements** | "While we're at it" additions; requirements discovered during UAT; gap between as-is and to-be wider than estimated | Requirements backlog growing during build phase; conference room pilots reveal new gaps; business process redesign underestimated | Strict scope governance; change request process enforced; gap/fit analysis completed before build |

---

## Go-Live Strategy Decision

| Strategy | Mechanism | Risk | Best For | ERP Consideration |
|----------|-----------|------|----------|-------------------|
| **Big-Bang** | All modules, all users, all locations at once | Highest — all-or-nothing; maximum blast radius | Simple implementations; single location; single module | Most common for ERP (transactional integrity requires all modules live simultaneously) [EXTENDED] |
| **Phased by Module** | One module at a time (e.g., Finance first, then Supply Chain, then Manufacturing) | Medium — requires integration between live and legacy systems during transition | Multi-module; module independence is high; legacy systems can bridge | Requires robust integration between live ERP modules and legacy systems; transaction flow across boundary is the critical risk [EXTENDED] |
| **Phased by Location** | All modules at one location, then roll to next | Medium — requires multi-instance management or configuration partitioning | Multi-site organizations; different locations have different readiness | Template approach: configure once, deploy many; local variations must be managed [EXTENDED] |
| **Parallel Run** | Old and new systems run simultaneously; reconcile outputs | Lowest risk but highest cost — double the operational effort | Financial systems where accuracy is non-negotiable; regulatory requirement | Doubles data entry effort; reconciliation is labor-intensive; useful for financial close validation [EXTENDED] |

**Decision criteria:** [SOURCE: C14 §3.2; EXTENDED for ERP context]
- Transaction integrity across modules → favors Big-Bang (no cross-system boundary during transactions)
- Organizational readiness varies by location → favors Phased by Location
- Module complexity varies significantly → favors Phased by Module
- Regulatory or financial accuracy requirements → favors Parallel Run
- Resource constraints → Phased approaches spread effort

---

## Cutover Planning Checklist

**Cutover = the orchestrated transition from old system to new system during go-live.**

| Phase | Activities | Gate | Go/No-Go Criteria |
|-------|-----------|------|-------------------|
| **T-30 days** | Final mock migration; cutover rehearsal; support team briefed; communications sent | Cutover Readiness Review | Mock migration successful; cutover plan approved; support model activated |
| **T-14 days** | Data freeze planning; final integration testing; user access provisioning; rollback plan tested | Pre-Cutover Gate | All critical defects resolved; data freeze schedule confirmed; rollback tested in staging |
| **T-7 days** | Pre-cutover data loads; system access validated; war room logistics confirmed; go/no-go meeting scheduled | Final Preparation Gate | Pre-cutover loads successful; system access confirmed; war room ready |
| **T-0 (Cutover Weekend)** | Legacy system freeze; production data migration; reconciliation; smoke testing; go/no-go decision | Go-Live Decision Gate | Migration reconciled; smoke tests pass; zero Critical defects; rollback window confirmed |
| **T+1 to T+5** | Hypercare support; daily triage; issue escalation; performance monitoring | Hypercare Entry | Go-live decision was GO; support team active; monitoring dashboards live |
| **T+5 to T+30** | Hypercare continuation; issue volume trending down; knowledge transfer to BAU support | Hypercare Exit Review | Issue volume below threshold; no Critical/High open defects; BAU support team capable |

**Gates that never compress (even in emergencies):** [SOURCE: C09 §3.6]
1. Security review
2. Data integrity verification
3. Backup before deployment
4. Rollback plan existence
5. At least 1 senior technical review
6. Post-deployment monitoring configured

**Rollback decision criteria:** [SOURCE: C14 §3.6, C02 §3.5]
- Error rate > 5% above baseline → evaluate rollback
- Response times degrade > 10% → evaluate rollback
- Data integrity failure (reconciliation discrepancy) → mandatory rollback evaluation
- Critical integration failure → mandatory rollback evaluation
- Rollback window: defined before cutover begins; once window expires, forward-fix is the only option

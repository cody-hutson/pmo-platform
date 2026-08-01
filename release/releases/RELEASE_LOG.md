# RELEASE_LOG

Per-release append log. State transitions: `DEPLOYED` (Stage 12 Phase B5) → `VERIFIED` (Stage 13 chore PR).

Spec: [`stage-12-execute.md § Phase B5`](../references/pipeline/stage-12-execute.md) (DEPLOYED row + visible-H4 Deployment Log); [`stage-13-close.md § Phase B`](../references/pipeline/stage-13-close.md) (DEPLOYED → VERIFIED transition).

**Date anchor — merge event.** The `Date` column dates the **merge of the release PR to `main`** (written at Stage 12), not the Stage-13 close-out. It is written once and never rewritten by the close. `RELEASE_INDEX.md` carries the **same** anchor and is sourced from this column; `RELEASE_DIGEST.md` and `CHANGELOG.md` carry the **close-out** anchor and may therefore differ by a day without contradicting this row. Taxonomy and format rules: [`date-variable-convention.md § Emission-Time Anchors`](../../core/standards/date-variable-convention.md). Rows predating that declaration are grandfathered — anchors are declared forward, never backfilled.

## Releases

| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v1.01 | v1.01-intake | #66, #101, #105, #237, #274 | #460 | `a3ddc5429df7d8e546da40547d28a6c7f9b75351` | `v1.01` | VERIFIED | 2026-06-01 |
| v1.02 | v1.02-triage-and-related | #38, #183, #347, #343 | #493 | `8a0e7a17f2f68e6d49acaf4384d652ee3bd4e02c` | `v1.02` | VERIFIED | 2026-06-02 |
| v1.03 | v1.03-bundle-and-related | (unrecoverable — re-versioned) | #515 | (unrecoverable — re-versioned) | (unrecoverable — re-versioned) | VERIFIED | 2026-06-02 |
| v1.04 | v1.04-planning | #42, #337, #517 | #540 | `e84913768ebbb1b97a8ab0af5ea5ac1195f78a60` | `v1.04` | VERIFIED | 2026-06-02 |
| v3.18 | v3.18-corpus-integrity-enforcement | #538, #410 | #562 | `44f670aa3846527f51952094013c84a4d75aad51` | `v3.18` | VERIFIED | 2026-06-03 |
| v3.19 | v3.19-close-out-reliability-backstops | #576, #581, #583, #584, #556 | #588, #591, #592, #598 | `a300f53519c8c35510f9b6b4acf2fbc698a75299` (#588), `bc09bed29e552896adf9eb6d2cce65ac93889e40` (#591), `abfe43a7c0ea82e6e74e295afa8b1d9d265dacb7` (#592), `532cdc922a5c39a6e0c2c39790f00316e9d8119c` (#598) | `v3.19` | VERIFIED | 2026-06-03 |
| public-flip-install-blockers (version-less) | public-flip-install-blockers | #606, #607, #608, #609, #610, #611, #612, #613, #614, #615, #144, #233, #242, #243, #632 (engineered); #265 (no-op) | #627 | `c0480974f42fc12e4c3e87b220d8d4850eb24190` (#627) | (none) | VERIFIED | 2026-06-04 |
| v1.05 | v1.05-planning-and-related | #64, #91, #116 | #401 | `0ffdd6d5c8bdec9b1fddbaf195f3730f4eecdf68` | `v1.05` | VERIFIED | 2026-06-05 |
| intake-elicitation-skill (version-less) | intake-elicitation-skill | #412 | #424 | `c5afc1d6d4a93e7e2da17f21460ff1b6d55de3cc` | `(none)` | VERIFIED | 2026-06-06 |
| v1.06 | v1.06-solutioning-and-related | #220, #216, #120 | #449 | `194e9723d10a2ebeef27d5ef8d398cae86a404bd` | `v1.06` | VERIFIED | 2026-06-06 |
| v3.20 | v3.20-release-corpus-verification-surface | #83, #85, #291, #425, #459 | #496 | `42656514caa32e8c03bc6ce19c29ff524fecf285` | `v3.20` | VERIFIED | 2026-06-07 |
| domain-aware-stage5-design (version-less) | domain-aware-stage5-design | #1, #345, #346 | #503 | `552b33efd5b98011d456eccb527da4e7925a8f14` | (none) | VERIFIED | 2026-06-07 |
| v1.07 | declarative-workitem-type-model | #506, #532, #507 | #526 | `d98c28dac07da9f99335c33c7c57f2acb70815aa` | `v1.07` | VERIFIED | 2026-06-07 |
| v1.08 | skill-suite-architecture-spine | #406, #2, #193 | #570 | `86ba6f69f8535e769e666025f8b37db2a3b7863d` | `v1.08` | VERIFIED | 2026-06-08 |
| memory-to-corpus-codification (version-less) | memory-to-corpus-codification | #356, #357 | #604 | `5b8eb2df14eec9edd28b3bbcf9d58cb70281e511` | (none) | VERIFIED | 2026-06-10 |
| v1.09 | agent-to-script-promotion | #187 | #636 | `3eecf0402ade8983c1aa9d2f34bc956c4979130c` | `v1.09` | VERIFIED | 2026-06-11 |
| v1.10 | failure-mode-coverage-completion-across-all-five-categories | #6, #138, #139, #140, #141 | #658 | `e4fbf16464d86fbf5d127154f6620610b6255bcf` | `v1.10` | VERIFIED | 2026-06-12 |
| v1.11 | cleanup-orphan-state-reliability | #333, #326, #53, #57 | #668 | `38f97d314c9499104f49d43b0c0345d7ed99921b` | `v1.11` | VERIFIED | 2026-06-12 |
| cross-reference-integrity-ci (version-less) | cross-reference-integrity-ci | #314, #169, #130 | #745 | `5ebec77d5997d7bbbc77cc21efd93ce2cdd5c168` | (none) | VERIFIED | 2026-06-13 |
| v1.12 | corpus-durability-enforcement | #316, #311 | #748 | `5714ae5ded31850c242f6e5d2b633d02c6e3dc09` | `v1.12` | VERIFIED | 2026-06-13 |
| v1.13 | runtime-test-gating | #319, #430, #706 | #747 | `fba3df41f1411aaaa07765791c5da8c11ed75939` | `v1.13` | VERIFIED | 2026-06-13 |
| v1.14 | adapter-config-foundation | #22, #703 | #759 | `71047a527eed34d24a0bf059acfc73c20b7ec6b5` | `v1.14` | VERIFIED | 2026-06-13 |
| v1.15 | platform-self-measurement-and-quality-method | #358, #359, #754, #125 | #858 | `dfb3836a2b8ac9807113ae1beb7a91629a3e2874` | `v1.15` | VERIFIED | 2026-06-13 |
| v1.16 | delivery-capacity-and-lifecycle-gating | #272, #273, #274, #275 | #859 | `a915daa94caa68423b42cbf7e7db69a4dfbc37e1` | `v1.16` | VERIFIED | 2026-06-13 |
| v1.17 | comms-writer-artifact-generator-anthropic-offload-refactor | #173, #174, #175, #176, #791 | #864 | `79d8827d0fb57f671ad49c0a80acf9e376bc5a55` | `v1.17` | VERIFIED | 2026-06-14 |
| v1.18 | cross-release-impact-model | #87 | #928 | `7d9307bbfcf317e29bfe34a772f5fac08a8934ea` | `v1.18` | VERIFIED | 2026-06-14 |
| v1.19 | sior-escalation-discipline-across-the-comms-triage-technical | #179, #178, #177, #934 | #941 | `787029df87e2ea6e961e9cdc5a030ffa248fcfd2` | `v1.19` | VERIFIED | 2026-06-14 |
| v1.20 | health-and-raid-determinism | #271, #270, #269, #261 | #933 | `626b9926270216c639b7c7c13727c0648733028f` | `v1.20` | VERIFIED | 2026-06-14 |
| parallel-launch-quota-budget-gate (version-less) | parallel-launch-quota-budget-gate | #23, #24 | #911 | `b2b5f69873075de6f9516e3f1d053a7829416114` | — | VERIFIED | 2026-06-14 |
| v1.21 | governance-as-code-quality-gates | #318, #79 | #1040 | `62595481ef14bb4f37dd841809f5ca8b1568ce45` | `v1.21` | VERIFIED | 2026-06-14 |
| v1.22 | deploy-toolchain-defect-cleanup | #88, #76, #332, #111, #104, #26, #331, #92, #1058 | #1081 | `edb99eb6313f6d991edc7ee0c231c918654c94fb` | `v1.22` | VERIFIED | 2026-06-14 |
| v1.23 | pmo-skill-reference-substrate | #224, #267, #268, #1011, #1012, #1013, #1014, #1015 | #1043 | `23cafa4be9408be7d4320d458c780f1df0e0a08c` | `v1.23` | VERIFIED | 2026-06-14 |
| v1.24 | pipeline-detection-bash-debt | #309 | #1068 | `10977af642da65c1bbb2b35332ff3cba70cf5bb4` | `v1.24` | VERIFIED | 2026-06-14 |
| v2.00 | 01-FNH-qa-change-release-hardening | #1127, #1128, #1129, #1130, #1131, #244, #245, #212, #248, #252, #246 | #1200 | `42ee22cf1279ffff1c0172d95de092a159025baa` | `v2.00` | VERIFIED | 2026-06-15 |
| v2.01 | 02-FNH-est-lifecycle-status-hardening | #264, #265, #266, #366, #180, #253, #254, #251, #256, #260, #263, #259 | #1240 | `97b66e12dd82ecb2131614577d9acf9314ba206e` | `v2.01` | VERIFIED | 2026-06-16 |
| v2.02 | 61-bundling-capacity-and-sizing-gates | #281, #290, #293, #294 | #1278 | `a081fec36b6e5551df8564d7fa2457e27d8f00c5` | `v2.02` | VERIFIED | 2026-06-18 |
| v2.03 | 03-ROLE-factory-and-pilots | #186, #185 | #1280 | `cc094b4409825ed95f2e1dd1d60f7b5b4e9aa4be` | `v2.03` | VERIFIED | 2026-06-18 |
| v2.05 | 35-agent-discipline-codification | #58, #63, #132, #426, #427, #502, #527, #530, #531, #546 | #1409 | `6ada20c3603532c3ad639a97796db7137b89cfd5` | `v2.05` | VERIFIED | 2026-06-19 |
| v2.06 | 36-ci-gate-trustworthiness-and-parallel-pr-safety | #1101, #673, #18, #90 | #1461 | `a74f814baa736494231fd01bc06fa1c9ea03d32d` | `v2.06` | VERIFIED | 2026-06-20 |
| v2.06.1 | 36-ci-gate-trustworthiness-and-parallel-pr-safety (hotfix) | #1475 | #1474 | `450b7e15d03774818fce6aa93590a605ea4e5517` | `v2.06.1` | VERIFIED | 2026-06-20 |
| v2.08 | 11-artifact-lineage-and-generated-surface-governance | #334, #1165 | #1468 | `17955bc2cee02beac08606ac0f4bd56f1471ca74` | `v2.08` | VERIFIED | 2026-06-20 |
| v2.07 | 10-ambient-intake-automation | #322, #1159, #1160, #1161, #1162, #1163 | #1460 | `3d3dd508b5042e1bbde97e510ef14e00b7b750d5` | `v2.07` | VERIFIED | 2026-06-20 |
| v2.04 | 62-close-out-registers | #1412, #360, #361 | #1533 | `cc10af42dfb2d4771b74107513c0e9cdd050486b` | `v2.04` | VERIFIED | 2026-06-20 |
| v2.09 | 37-deploy-sh-script-health | #86, #400, #659, #661, #665, #758, #760, #984, #1036, #1089, #1104 | #1551 | `581863b3d611356e4b88ed3891cc9e7e642a5dde` | `v2.09` | VERIFIED | 2026-06-20 |
| v2.10 | 24-agent-artifact-disciplines | #144, #413 | #1556 | `cb81165ef0221b75b721ded1a01c4aa02d2d385a` | `v2.10` | VERIFIED | 2026-06-20 |
| v2.11 | 04-ROLE-delivery-coverage | #450, #1109, #1110, #1111, #1112, #1113, #1114, #1115, #1116, #1117, #1118, #1119 | #1555 | `78ea10a48a9bf6b91ab94076e688c9daea340f26` | `v2.11` | VERIFIED | 2026-06-20 |
| v2.13 | 63-finding-disposition-discipline | #100, #215, #221, #285 | #1657 | `b2c12adf8381a724be2b7770ffdd66d655949f6f` | `v2.13` | VERIFIED | 2026-06-20 |
| release-version-stamping (version-less) | release-version-stamping | #1643 | #1693 | `1d1c0ec2ed3475be4403f5d606fd5a05f7501e11` | (none) | VERIFIED | 2026-06-20 |
| v2.14 | 71-autonomy-phaseout-foundation | #164, #165 | #1636 | `404037103e265f6548fef106f1c38d9ba9694bd8` | `v2.14` | VERIFIED | 2026-06-21 |
| v2.12 | 12-field-first-intake-enforcement | #27, #54, #344 | #1699 | `28860f1c76cc7889a225d1f109b16ed6e185d831` | `v2.12` | VERIFIED | 2026-06-20 |
| v2.15 | 05-ROLE-sustain-coverage-router | #1120, #1121, #1122, #1123, #1124, #181, #1564 | #1700 | `b8ce4f3540035a28f8ebfffbadb05ca453c3e5c7` | `v2.15` | VERIFIED | 2026-06-20 |
| v2.16 | release-version-claim-determinism | #1697, #1676, #1673, #1674, #1008, #65, #66, #1675, #769, #1677, #1679, #1678, #1092, #950 | #1768 | `44b09d4ba647b7917f9b376a1f1575e8cd29ed31` | `v2.16` | VERIFIED | 2026-06-21 |
| v2.17 | architecture-altitude-discipline | #1764, #1774, #1775, #1776, #1767, #1765, #1766 | #1812 | `fae1f8d450c3768207d7f89e5204e8d8c4068aba` | `v2.17` | VERIFIED | 2026-06-21 |
| v2.18 | 86-hybrid-comanagement-decouple | #1778, #32 | #1797 | `4fdaf160f1bccc41a01185ac00ad2a16e087ce35` | `v2.18` | VERIFIED | 2026-06-21 |
| v2.18.1 | operator-instance-path-decoupling | #1830 | #1849 | `85a273621545af4abe5c8b718ebc3ea7a03d14b0` | `v2.18.1` | VERIFIED | 2026-06-22 |
| public-flip-depersonalization-enforcement (version-less) | 43-public-flip-depersonalization-enforcement | #383, #324, #1827, #529, #1137, #323, #411, #1823, #1098, #1850; #376 (verify-only KEEP) | #1847 | `939079d674a8a32f3fa7ff6e23c284893464ff8c` | (none) | VERIFIED | 2026-06-21 |
| v2.19 | comanagement-shim-retirement | #1846, #1853 | #1851 | `85d3f247a33e5e01713b1aa7acd99c672ae43dcd` | `v2.19` | VERIFIED | 2026-06-22 |
| v2.21 | decision-rendering-standardization | #320, #321, #337 | #1877 | `ae0413665a3402dfc4afcbd54b3fa1b313c575ab` | `v2.21` | VERIFIED | 2026-06-23 |
| v2.20 | 13-field-lifecycle-and-cmdb-automation | #156, #1155, #154, #1156, #1865, #1866, #202, #208, #752 | #1878 | `193a523eae4542e282600e911fe2dc6a79ac0893` | `v2.20` | VERIFIED | 2026-06-23 |
| declarative-gating-model (version-less) | declarative-gating-model | #1870 (engineered); #1875, #1876 (research spikes) | #1890 | `1dfa3488778b7c96ffc1ccb7d22981f97497026f` | (none) | VERIFIED | 2026-06-24 |
| v2.22 | 25-comms-and-facilitation-reference-substrate | #317, #378, #56 | #1919 | `1e5b6bace819a672faaedde24504c6101d986c72` | `v2.22` | VERIFIED | 2026-06-25 |
| v2.23 | 14-functional-people-graph | #1897, #315, #1166, #1898, #1899, #1900 | #2020 | `ca2015a8dd025601f52f1c86ba79fc9529bf9e34` | `v2.23` | VERIFIED | 2026-06-26 |
| v2.26 | 85-people-graph-activation | #2040, #2041, #2042 | #2072 | `2426d92520bda725b9e96c8cca205edfdff239f8` | `v2.26` | VERIFIED | 2026-06-26 |
| v2.24 | 26-corpus-conventions-and-standards-hygiene | #77, #81, #113, #1094, #751, #764, #171, #163, #580, #663 | #2019 | `fb0d88af4de5a45612564942636022537a1108d0` | `v2.24` | VERIFIED | 2026-06-26 |
| v2.25 | 76-hub-spoke-orchestration-discipline | #31, #78, #189, #210, #879, #1669 | #2016, #2017 | `029b5c6320bb873f681c5f7a04195112ef99040e` | `v2.25` | VERIFIED | 2026-06-26 |
| v2.27 | 22-ticket-information-architecture | #436, #545, #211 | #2070 | `38905e4b6a1315cca85bf3cdb4f55a28d02cd807` | `v2.27` | VERIFIED | 2026-06-26 |
| v2.28 | 15-generated-vs-source-provenance | #205 | #2091 | `0fdd8b763b1e5bbd9e731d52d1e0a44d17d21dee` | `v2.28` | VERIFIED | 2026-06-26 |
| v2.29 | 27-corpus-drift-reconciliation | #49, #94, #107, #127, #305, #498, #857, #881, #1100, #2095 | #2124 | `92494ed447b43b79924f4a92cf4d3c2593247506` | `v2.29` | VERIFIED | 2026-06-26 |
| v2.30 | 38-governance-cross-reference-currency | #121, #677, #399, #2081, #2080, #753 | #2122 | `07a5e9cd951c6e995e7c06ab917245636a54b6c7` | `v2.30` | VERIFIED | 2026-06-26 |
| v2.31 | 16-knowledge-management-discipline | #1073, #1074, #1075, #1076, #1077, #249 | #2188 | `bca1f86` | `v2.31` | VERIFIED | 2026-06-27 |
| v2.32 | 104-skill-registry-identity-and-currency | #1811, #1658, #1211 | #2249 | `42f029553574e8c69e4e795e68b65b10829f856c` | `v2.32` | VERIFIED | 2026-06-27 |
| v2.33 | 40-initiative-roadmap-vocabulary-and-home | #1038, #416 | #2280 | `c5099a2b6c1709a635e6bdbb483f8dc692ebfa58` | `v2.33` | VERIFIED | 2026-06-27 |
| v2.34 | 97-knowledge-and-decision-confidence | #1102, #564, #2214, #1945, #453 | #2356 | `ffffa3b` | `v2.34` | VERIFIED | 2026-06-28 |
| v2.35 | 104-agent-decision-confidence | #2286, #2287, #2288, #2289, #2290 (parents #2283, #2285) | #2336, #2337, #2348, #2350, #2352 | `3bfd391ad4b6dfd466f59d8b79b82691d0444571` | `v2.35` | VERIFIED | 2026-06-27 |
| v2.36 | 69-triage-and-bundling-signals | #500, #283, #662, #280, #292, #225 | #2284 | `1a1d51af6f96875f782ce40325a5ba9e231e7643` | `v2.36` | VERIFIED | 2026-06-28 |
| v2.37 | 91-release-notes-conformance | #2120, #2082, #2085; #1290 (absorbed, ms 72) | #2378 | `a41df5eb617e9a8a7169ab4eb16a5b83e64bc3dd` | `v2.37` | VERIFIED | 2026-06-28 |
| v2.38 | 72-closeout-output-determinism | #667, #82, #37, #38, #1705, #1681, #1680, #1682, #84 | #2398 | `5b7ee811c2bfdd3a85935524e2d9d1775ed9c12b` | `v2.38` | VERIFIED | 2026-06-28 |
| v2.39 | 60-audit-cadence-and-learning | #167, #168, #46 | #2421 | `711f81de5a528b96ab588f01905edcab8dfbf1fb` | `v2.39` | VERIFIED | 2026-06-29 |
| v2.40 | 17-per-project-processing-orchestration | #237, #1157, #243, #1158 | #2426 | `9b50b403fa5ea5cf5ba11dc42a6f45b3b934dc01` | `v2.40` | VERIFIED | 2026-06-29 |
| v2.41 | 99-rca-and-corpus-anchor-hygiene | #1562, #1883, #1918, #2218 | #2438 | `5bfffe1e2bb4a2265f1d3a39ff043557b66e5b06` | `v2.41` | VERIFIED | 2026-06-29 |
| v3.21 | 34-terminology-and-controlled-vocabulary | #68, #128, #432 | #2487 | `26c32a4e0e1888ab17c99a2de13166249090d7b2` | `v3.21` | VERIFIED | 2026-06-29 |
| v3.22 | 18-pmbok-coverage-and-project-schema | #206, #262, #351, #371 | #2489 | `3aded2afa122f8e24b63d7ec89dced27b31582cb` | `v3.22` | VERIFIED | 2026-06-29 |
| v3.23 | 06-HEALTH-project-health-check | #1125, #1126 | #2488 | `97310f9457c5ce25f2543dd9a7beed54941ef149` | `v3.23` | VERIFIED | 2026-06-30 |
| v3.24 | release-hub-orchestrator-skill | #2115, #2212 | #2497 | `25f46256bd2747d1eded751771b2e8f024c7d1c0` | `v3.24` | VERIFIED | 2026-06-30 |
| v3.26 | 39-governance-drift-canonicalization-ci | #133, #135, #228, #757 | #2529 | `12ac517c54800101d5f473cae8371a9407fb5b1b` | `v3.26` | VERIFIED | 2026-06-29 |
| v3.27 | 28-corpus-frontmatter-standardization | #295, #109, #2220 | #2545 | `46b1541f1423c9f4859d28a66494b2c357f11d51` | `v3.27` | VERIFIED | 2026-06-30 |
| v3.28 | 41-label-taxonomy-canonicalization-backfill | #80, #74, #749 | #2586 | `70f6de8667e14038993844fe6ff84daa21f5e1d9` | `v3.28` | VERIFIED | 2026-06-30 |
| v3.29 | 73-concurrent-execution-safety | #19 | #2585 | `0fe190564c4066962f8d0c9af6235d7a70ca4266` | `v3.29` | VERIFIED | 2026-06-30 |
| v3.30 | 88-skill-anchoring-software | #2165, #2167, #2169, #2170, #2171, #2209 | #2596 | `6264b001986c5327deae531152a53334f7ae8d9f` | `v3.30` | VERIFIED | 2026-06-30 |
| v3.32 | 64-hub-autonomy-conformance | #381, #377 | #2589 | `bdadfae4592fa460ca33a354a5861043ec866338` | `v3.32` | VERIFIED | 2026-06-30 |
| v3.33 | 89-skill-anchoring-governance | #2172, #2173, #2174, #2175, #2176, #2181 | #2614 | `3daa866de44382dc0af5121d2a4bcb6ae5ffdc97` | `v3.33` | VERIFIED | 2026-06-30 |
| v3.34 | 65-pipeline-telemetry-suite | #7, #143, #2612 | #2621 | `2b813f3c71e5e5e86df93b0d0f1dbc85712abf1e` | `v3.34` | VERIFIED | 2026-06-30 |
| v3.35 | 20-records-management-naming-and-cleanup | #232, #277, #369, #372 | #2610 | `47228d5ba391bbc432ef1b1f1eb5d88458b8e078` | `v3.35` | VERIFIED | 2026-06-30 |
| v3.36 | 90-skill-anchoring-process-support-change | #2177, #2178, #2179, #2180, #2210, #2211 | #2648 | `32a2f16b2ce3435fdcdcbd546b7b6ce6b162c9b9` | `v3.36` | VERIFIED | 2026-06-30 |
| v3.37 | 21-shared-entity-storage-layout | #159, #362, #363 | #2676 | `f174d1909fdbab5d64f73be9d0421187e366f276` | `v3.37` | VERIFIED | 2026-06-30 |
| v3.38 | 66-release-identity-and-spec-hardening | #3, #226, #75 | #2683 | `27ddc19bcba3d9c112baf864e87ee25fb4ac9c88` | `v3.38` | VERIFIED | 2026-06-30 |
| v3.40 | 30-doc-link-drift-drainage | #108, #131, #2684, #2700 | #2712 | `366e4bcc271beabe9dc9f4a4b3231a16456dc4b9` | `v3.40` | VERIFIED | 2026-06-30 |
| v3.41 | 07-INFRA-hygiene-measurement | #1135, #1136, #1132, #1133, #571, #676, #16, #17, #704 | #2704 | `7f293f2eed8390802661267d694864239d0bc9d7` | `v3.41` | VERIFIED | 2026-07-01 |
| v3.42 | 85-cleanup-orphan-tooling-reliability | #2216, #684, #683, #670, #655, #669, #2790 | #2789 | `71c773bc042d76cec4bf1569ae63dca151cad150` | `v3.42` | VERIFIED | 2026-07-01 |
| v3.43 | 67-spoke-execution-safety | #307, #47, #1639, #1642, #1351, #59 | #2799 | `fb3dc6b873009da2b43943836d9b4b1a126b01cf` | `v3.43` | VERIFIED | 2026-07-01 |
| v3.44 | 78-pipeline-triage-automation | #286, #282 | #2801 | `adf41b10a76cce7223d5ae235fc0896642d85974` | `v3.44` | VERIFIED | 2026-07-01 |
| v3.45 | 42-pipeline-skill-doc-reconciliation | #887, #499 | #2851 | `1986f0d02246eec447e5ba3f1b302627181d3ada` | `v3.45` | VERIFIED | 2026-07-01 |
| v3.47 | 23-tracker-comms-session-config | #234, #247, #241, #239, #233 | #2860 | `1ac0ed1d3d4047bf989ffc367942774932e52346` | `v3.47` | VERIFIED | 2026-07-02 |
| v3.48 | 105-knowledge-corpus-tail-closeout | #930, #1087, #1093 | #2918 | `dd9c2843ab80e08740c3f77032b54b02cd7cb039` | `v3.48` | VERIFIED | 2026-07-02 |
| v3.49 | 08-INTAKE-governed-file-movement | #240, #565, #289 | #2861 | `ee649ad3f42719860b5a5f565672e3c8590283cc` | `v3.49` | VERIFIED | 2026-07-02 |
| v3.50 | 68-stage-gate-criteria-completeness | #28, #96, #118, #29, #501, #889, #119 | #2928 | `d5e0883ed20751e0f242a0d3b920d6c1b7f9a4d5` | `v3.50` | VERIFIED | 2026-07-02 |
| v3.51 | 106-skill-suite-tail-closeout | #931, #2208 | #3013 | `1139a062d22c369e229541932c31c45321e95a06` | `v3.51` | VERIFIED | 2026-07-02 |
| v3.52 | 83-eval-framework-completion | #199, #209, #279, #367 | #3060 | `6a647c6493b68688d8ee3fcb7dbbf0505b01c699` | `v3.52` | VERIFIED | 2026-07-01 |
| v3.53 | 100-adr-and-frontmatter-schema | #2156, #2155, #2157, #2068, #1487 | #3049 | `c0e8b44ce416a23ed0a9d23f66b81c442022296d` | `v3.53` | VERIFIED | 2026-07-02 |
| v3.56 | 81-stage3-bundling-composer-and-identity | #25, #30, #52, #415 | #3096 | `328069f1bfbfcc6563b0b2c2e33b2f7d41e85cc0` | `v3.56` | VERIFIED | 2026-07-02 |
| v3.57 | 80-solutioning-and-engineering-skill-modes | #674, #505 | #3082 | `e2893a05ebdb7dc4ff1d1eaab2f2c112dcdb0216` | `v3.57` | VERIFIED | 2026-07-02 |
| v3.58 | 09-FRONTIER-system-business-specialists | #407 | #3099 | `424ae10bec36e25e776dd05d4f6247029bda4fac` | `v3.58` | VERIFIED | 2026-07-02 |
| v3.59 | 44-repo-structure-and-filesystem-hygiene | #73, #230, #1079 | #3011 | `bb4b461bee97b1e000d9b0bc214947b4840cbd9d` | `v3.59` | VERIFIED | 2026-07-02 |
| v3.60 | 86-methodology-pack-foundation | #1967, #1968, #1970 | #3097 | `7d251f53590e6b90be7c8e01d17a45a117679723` | `v3.60` | VERIFIED | 2026-07-02 |
| v3.61 | 107-pda-tail-closeout | #3081, #1770, #1769, #2424 | #3098 | `e25eb5147816253f8f9df128241667344aaf2c76` | `v3.61` | VERIFIED | 2026-07-02 |
| v3.62 | 31-immutable-adr-system | #431, #15, #541, #3200 | #3193 | `0c4a3f8fc72954bbfa555eebc42fb0798562dae4` | `v3.62` | VERIFIED | 2026-07-03 |
| v3.63 | 74-controlled-deployment-environment-and-modes | #213, #214, #379 | #3199 | `3d8780ffd2f8f3371c183e94593f9472a22356fa` | `v3.63` | VERIFIED | 2026-07-03 |
| v3.64 | 84-executable-acceptance-testing | #218, #217, #197 | #3202 | `4a63bfafbf3302d5ed7218458e95ade0ae750d47` | `v3.64` | VERIFIED | 2026-07-03 |
| v3.65 | 70-verification-execution-surface | #99, #170, #103, #227 | #3205 | `b1a21527d315929b4a0ae1f4d684cd8122dae283` | `v3.65` | VERIFIED | 2026-07-03 |
| v3.65.1 | 109-comment-trust-boundary | #3261 | #3304 | `814c9db3cfa7ff39608cce518f578cae979ba65c` | `v3.65.1` | VERIFIED | 2026-07-04 |
| v3.66 | software-domain-templates | #71, #2149, #2150 | #3308 | `671e0bf609e08b59d60f683b0875c3f488552881` | `v3.66` | VERIFIED | 2026-07-09 |
| v3.67 | 87-methodology-pack-catalog | #1085, #1067, #1788, #1803, #1973 | #3316 | `883baa6ca27ea0936bfc5d7a8ff23930f99953dd` | `v3.67` | VERIFIED | 2026-07-10 |
| v3.68 | 79-qa-devtest-modes-and-automated-eval-execution | #222, #219, #2226, #172 | #3314 | `3103304260d6b2b930e2477fa4825a220a61a369` | `v3.68` | VERIFIED | 2026-07-10 |
| v3.69 | 94-deploy-check-drift-remediation | #3198, #2213, #2217, #3375 | #3376 | `68740d58e947ed17ed6fcbed0c36986531460e54` | `v3.69` | VERIFIED | 2026-07-10 |
| v3.69.1 | security-advisories-9cjm-rw36 | GHSA-9cjm, GHSA-rw36, #3384 | #3384 (advisory merges are private-fork — no PR number) | `075390e5da82f00c6484ca35108988a4ea6a4810` (#3384), `849e3ec5af05f67cda5963ffaf7a1f5be948bd56` (GHSA-rw36), `8304098c30d95d8703e02abfb7f84b7ac6da4240` (GHSA-9cjm) | `v3.69.1` | VERIFIED | 2026-07-11 |
| v3.70 | 98-pipeline-freshness-and-spoke-safety | #1685, #1960, #2083, #2215, #1561 | #3379 | `452dc96645d25f4c8191db5bf39c2802993dd9e8` | `v3.70` | VERIFIED | 2026-07-11 |
| v3.71 | pda-folder-intake-and-provenance | #2374, #2375, #2376, #2377 | #3391 | `080876925c7d0624ea3e765d48d36188c56fb472` | `v3.71` | VERIFIED | 2026-07-11 |
| v3.72 | release-hub-mode-r-and-o | #2680, #2657, #2576, #2355, #2428 | #3405 | `61b0ae1d95830aea5e2d3281a8744cd8f20506ec` | `v3.72` | VERIFIED | 2026-07-12 |
| v3.73 | security-advisories-g9g6-fxcr | GHSA-g9g6, GHSA-fxcr | #3426 | `874f59abee96965a4561a032bb186d7d2377715f` | `v3.73` | VERIFIED | 2026-07-12 |
| v3.73.1 | update-refresh-deployed-hooks | #3430 | #3431 | `421658d395a207d6525f596cbf71440d115127ac` | `v3.73.1` | VERIFIED | 2026-07-12 |
| v3.74 | build-security-hardening | #3407, #3409, #3408 | #3428 | `6d70303c246b006616aea78c56cc7062f811758a` | `v3.74` | VERIFIED | 2026-07-12 |
| v3.75 | 101-skill-and-data-entity-hygiene | #2074, #2166, #2168, #2066 | #3544 | `1975d42afdfeb934ab6b2a7f73653f7681a45a6e` | `v3.75` | VERIFIED | 2026-07-16 |
| v3.76 | knowledge-corpus-hygiene | #2221, #2702, #2701, #2917, #380 | #3545 | `da4c116249cebf6df694cad2be33ab2f40f399f5` | `v3.76` | VERIFIED | 2026-07-17 |
| v3.77 | skill-hardening | #155, #2699, #3114 | #3540 | `b885d7361e524cab0c2da2edfcace6a05e8a6984` | `v3.77` | VERIFIED | 2026-07-17 |
| v3.78 | pda-rollup-and-portfolio | #2578, #157, #1771, #276, #1169 | #3549 | `399450827f07ace9e1f11e2f3ec76fc8a3d68a81` | `v3.78` | VERIFIED | 2026-07-17 |
| v3.79 | 95-deploy-tooling-resolver-and-test-parity | #2158, #1476, #1471, #1477 | #3543 | `53c28fbe05107f41b3be8e8f0bfebde7c2124a96` | `v3.79` | VERIFIED | 2026-07-17 |
| v3.80 | close-out-reliability-hardening | #2539, #2435, #2540, #2678 | #3618 | `4f9420c72dfea27f7f857fa48dcbd6be0adf9614` | `v3.80` | VERIFIED | 2026-07-21 |
| v3.81 | 92-version-identity-and-parser-ssot | #2075, #1800, #1801, #2048, #1286 | #3656 | `e1bcb48fa4ba55cf6f6ce8403fdd76864054eb9d` | `v3.81` | VERIFIED | 2026-07-22 |
| v3.82 | governance-doc-reconciliation | #2472, #2473, #2854, #3289, #2805, #3385, #3386 | #3667 | `a0fe5e61de1894239133c18e55f9d1da63819f86` | `v3.82` | VERIFIED | 2026-07-22 |
| governance-ci-checks (version-less) | governance-ci-checks | #1039, #2219, #2682, #2106, #2685, #3009, #1490 (retagged in at Stage 9) | #3662 | `f0d95a58baeb67f7bbabf565259e6c128b79b153` | (none) | VERIFIED | 2026-07-22 |
| v3.83 | pipeline-telemetry-tail | #3301, #2646, #2647, #2645, #2423, #166 | #3657 | `4dcf8298c33b79bffc6efebebb7b53bafd631869` | `v3.83` | VERIFIED | 2026-07-22 |
| v3.84 | version-identity-and-corpus-ledgers | #3016, #3108, #3109 | #3654 | `1dd1ca01a8dbf471f389bdd8a388775b5899e4ea` | `v3.84` | VERIFIED | 2026-07-24 |
| v3.85 | close-out-hardening-wave-2 | #3118, #3322, #2600, #3215 | #3729 | `68736d5e6340838c5cd15512e42f9c1f0260a7db` | `v3.85` | VERIFIED | 2026-07-24 |
| v3.86 | structure-records-and-review-signals | #2225, #2021, #681 | #3797 | `e1b631414c7fc36b38ed07e5de36f1057ffe63b8` | `v3.86` | VERIFIED | 2026-07-24 |
| governance-ci-gates (version-less) | 93-governance-ci-gates | #1632, #1485, #1484, #2656, #1486, #3795 | #3799 | `18292527e38f0994e397424c31ed34f6d1f74052` | (none) | VERIFIED | 2026-07-24 |
| v3.87 | design-artifact-backfill | #3725, #3614, #3798, #3441 | #3796 | `27c7d5efc0259946d5990e7706bbbcd41f64cd3d` | `v3.87` | VERIFIED | 2026-07-24 |
| v3.88 | deploy-and-tooling-defect-cleanup | #2341, #3210, #2439, #3578, #3722, #2232 | #3794 | `3368d98ebf4a2b822e2ebfb68a20aa07b486eb77` | `v3.88` | VERIFIED | 2026-07-24 |
| v3.89 | template-system-governance-wave-1 | #3380, #3381, #2855 | #3913 | `5fff643ade4fa7124466a23852d7108a2d8ca6d4` | `v3.89` | VERIFIED | 2026-07-25 |
| v3.90 | blast-radius-scan-correctness | #3300, #3291, #675, #3120 | #3924 | `09eda3bdc06d3f3682baf339b4958ed697a9b24b` | `v3.90` | VERIFIED | 2026-07-25 |
| v3.91 | 46-cross-platform-install-experience | #382, #299, #303, #302, #384, #304 | #3925 | `da9fc42aecc1f33cfd7a12bc750014adbecd3f12` | `v3.91` | VERIFIED | 2026-07-25 |
| v3.92 | architecture-baseline | #877, #912, #1097 | #3923 | `3892473cbdbbc3fe6266dba4d18b5ce2925b1465` | `v3.92` | VERIFIED | 2026-07-25 |
| v3.93 | release-identity-and-plan-naming | #2548, #3993, #3107, #3119, #3307 | #4029 | `01e102ad6f9515804880dfa8abd9740b0fa16dde` | `v3.93` | VERIFIED | 2026-07-25 |
| v3.94 | intake-and-gate-protocol-hardening | #779, #3303, #792, #1007 | #4030 | `5aed5e6015e47a5ad919f1815e0518b27b3d80e6` | `v3.94` | VERIFIED | 2026-07-26 |
| v3.95 | 56-runtime-config-and-posture | #1212, #102, #340, #310, #339 | #4037 | `67f1c0c5f2b37aa3a195eb517b79593f207f510c` | `v3.95` | VERIFIED | 2026-07-26 |
| v3.96 | agent-finops-foundation | #3909, #3910 | #4032 | `ac31eb29f514eabab96b0b9198ee0971e317f2db` | `v3.96` | VERIFIED | 2026-07-26 |
| v3.97 | build-philosophy-corpus | #2601, #2379 | #4133 | `c290126c0250f2466f9a5dcf2dbf320f006a6f86` | `v3.97` | VERIFIED | 2026-07-27 |
| v3.98 | release-hub-mode-r-depth | #2574, #2575, #3327 | #4180 | `5f8aa26bfb5ca004ee97bc2f4794473a86a279da` | `v3.98` | VERIFIED | 2026-07-28 |
| v3.99 | release-hub-response-convention-enforcement | #4020, #4021 | #4171 | `3f8af4a722878e931e5cd5d4d96df5a1684d6966` | `v3.99` | VERIFIED | 2026-07-28 |
| v3.100 | decision-telemetry-emission | #3712, #3704, #4051, #3723, #4025, #4026 | #4187 | `35f71ae70678a1e2a61d80a02c7a7a5f8191d009` | `v3.100` | VERIFIED | 2026-07-28 |
| v4.0 | agent-finops-intelligence | #4044, #4043, #3912, #3911, #3610, #3611, #3612, #3613 | #4209 | `20894ba6ae4fd98aea0c6f22809674b5b35d68a0` | `v4.0` | VERIFIED | 2026-07-29 |
| v4.01 | decision-audit-and-learning | #4024, #3705 | #4167 | `66c5fb263a27a810c1edf5820f08c96f426c6e29` | `v4.01` | VERIFIED | 2026-07-30 |
| v4.02 | release-closeout-integrity | #3586, #3587, #3665, #3701, #3718, #3724, #4339 | #4330 | `2822071f906d86781f5a66b9ebabe65ccfa2df64` | `v4.02` | VERIFIED | 2026-07-31 |
| v4.03 | closeout-output-set-integrity | #3727, #4176, #3113, #1550, #2422 | #4333 | `2adf533e1a2f9d3c55be81d86d959718ca53e60e` | `v4.03` | VERIFIED | 2026-08-01 |
| v4.04 | check-enforcement-fidelity | #4208, #4183, #4177, #3833, #4178, #4169 | #4334 | `838ae31485a650da6d87b435ac776ac708de93fc` | `v4.04` | VERIFIED | 2026-08-01 |

#### Deployment Log v4.04
**Files deployed:** check-enforcement-fidelity — one release PR #4334 (`release/check-enforcement-fidelity → main`, merge-commit `838ae314`), 6 delivery slices on one branch, 33 commits, 28 files (+2621/−64). The release's unifying property is **verification instruments that claimed to enforce something and did not**, plus the convention governing that claim, which had been silently excluding a whole class of them. **#4208** widens the Requirement-(b) scope table in `core/standards/gate-efficacy-standard.md` to admit **prose-declared normative predicates** as a third realization alongside the two syntaxes already covered — extending the existing convention rather than minting a parallel one — and ships `core/ADRs/ADR-104-complementary-pair-registration-and-canonical-into-package.md` (D-1 + D-2). **#4183** replaces `--check-package-freshness`'s exit-0-on-STALE with a fail-closed contract (`FRESH→0` / `STALE+warn→2` / `STALE+enforce→1` / unexpected→`1`); the `deploy.sh` mapping and the workflow gate decision land in **one commit** deliberately, because the workflow reads `if RC -eq 0 → green; else exit 1` and a split would have turned warn-mode CI red on the advisory `2`. **#4177** replaces Check 45(b)'s existence-only predicate with a fixed-string containment assertion, so a mis-pinned `governing_doc` can no longer pass silently; it lands `advisory`/warn, **(b′)-forced**, since Check 45 has no CI mirror. **#3833** converts **both** of Check 31's override-marker probes from a `pipefail`-racing pipe to a here-string. **#4178** registers the canonical↔skill-local `tracker-schemas.md` pair in a machine-checkable 5-field registry (`core/deploy/allowlists/complementary-reference-pairs.txt`), makes the packager fail **closed** on a missing registry, and ships the canonical into `tracker-manager.skill` through a `TEMPLATE_SYNC_MAP` entry rather than a hand-coded injection. **#4169** corrects an operator-local judge instrument; it is git-ignored, contributes **no diff to this PR**, and was accepted by operator attestation. Three findings changed the implementation and each was caught by verification rather than review: **#3833's premise was inverted** — Class V looked stable at 45 and was assumed unaffected, but was over-reporting **5× on every run** (45 against a true 9) because its three dropped files all exceed 71 KB and failed *deterministically*, so scoping the fix to the visibly-flaky probe would have left a permanently-wrong number that never twitches (measured Class L 477→**93**, Class V 45→**9**, against a 164/26 census); **#4178's resolver risk was worse than framed** — `resolve_template_sync_source()` resolved not *ambiguously* between canonical and mirror but to **neither**, a basename `case` falling through to a default that produces a third, non-existent path, so the registry entry alone would have failed Check 13 and returned non-zero from the packager on every build; and **#4183's fix required an atomicity nobody had recorded**. Engineering Commit 0 landed the release plan at its slug-only name `release/releases/plans/check-enforcement-fidelity_RELEASE_PLAN.md`.
**Mechanism:** git merge-commit (PR #4334 → main at `838ae31485a650da6d87b435ac776ac708de93fc`; a true **two-parent** merge commit — parents `620751d0` (main) and `df6a9289` (release head) — so the plan's declared `git revert -m 1` rollback form applies). **Plain `gh pr merge --merge`; no `--admin`, no signature bypass, zero force pushes, zero history rewrites.** The release-PR merge was expected to require `--admin` under this repo's protection; it did **not** — protection reads `required_approving_review_count: 0`, `enforce_admins: false`, and all **9 required contexts** were present and green, so the plain form succeeded on the first attempt. The command returned **no stdout and no stderr with exit 0** — the exact empirical shape the Phase B merge-verification protocol exists for — and was confirmed only by the mandated `gh pr view --json state,mergeCommit` assertion (`MERGED` + non-null `mergeCommit.oid`), not by the merge command's own silence. No merge strategy was declared in the plan, so Phase A.4.1's `--merge` default applied; Phase A.4.2 recorded the allowed-strategies map (`merge:true`, `squash:true`, `rebase:true`) for the audit trail. Signed-annotated tag `v4.04` at the merge SHA (annotated tag object `4bd5ae75159b7b63659881f5514330c65cfcd36c`, object type `tag` not `commit`; `git tag -v v4.04` → *Good signature*, ED25519 key `SHA256:/2bw1mPVjUqzNzdOzeS5sDV2DmwczAS1g7NZiFxbjq8`; GitHub API `verification.verified = true`, `reason = valid`; tagger is the repo's no-reply identity). Claim bound at the Stage-12 **atomic ref-CAS** via `claim-version.sh --sha 838ae31485a6 --bump minor` — **first-attempt win, zero CAS collisions, zero signing bypasses**. **This release lost two version slots while in flight and the third was recomputed, not carried.** The plan-time next-free was `v4.02`; the sibling `release-closeout-integrity` (PR #4330) took it, the sibling `closeout-output-set-integrity` (PR #4333) then took `v4.03`, and `v4.04` was recomputed from scratch against freshly-fetched authoritative refs at the claim instant rather than inherited from the Stage-10 dry-run — the ordered claim sequence is `v4.02 → v4.03 → v4.04`, handed to the Stage-13 re-version ledger. That the recomputed number happened to equal the dry-run's is a coincidence of arrival order, not a reason the dry-run could have been trusted: the dry-run reads a population that is only transiently valid, which is precisely what produced both prior losses. Phase A.5.6's stale-carried-label divergence class was recorded **FREE**, and the reason is worth stating exactly — on the three surfaces A.5.6 enumerates (branch commit-message labels, PR title, plan version field) the branch is **slug-primary** per ADR-092/ADR-036, so there was no carried label that could go stale and no relabel to apply before the merge. Two residues survive on surfaces A.5.6 does not read and are recorded rather than rewritten: one branch commit *subject* carries the historical narrative `re-version v4.02 -> v4.03` (accurate as history, immutable without a prohibited force-push), and the release-PR body's H2 header still reads `v4.03` (the PR body's own claim that "no commit subject carries a version" is falsified by that commit). **ADR-092's claim-time stamp did not fire, and the reason is a defect rather than a choice.** `--stamp-slug` was omitted because it would have HALTed at pre-flight: the plan carries **zero** `{{RELEASE_VERSION}}` tokens — the placeholder was substituted with the literal prose *"the release version (bound at Stage 12)"*, which now stands in the plan's H1 title and inside a Deviation-Log sentence where a version was meant to render. The plan therefore stays at its slug-only name. Phase B4 **did** require a `deploy.sh --deploy` run — the first in this `v4.x` sequence to do so — and Phase J.5's rebuilt-package diff is nonetheless empty: the packager deployed the already-fresh in-repo package rather than rebuilding it, and the session worktree is byte-clean with zero tracked-file changes after the deploy.
**Timestamp:** 2026-08-01 (release merge 2026-08-01T11:28:01Z UTC; signed-annotated tag `v4.04` at the merge SHA; operator-local deploy date Saturday 2026-08-01)
**Cycle-Time:** N/A — (T_GO=n/a; T_DEPLOY=n/a; mechanism: compute-cycle-time.sh) — the tool reports no `gate-outcome/plan-review-go` and no `deployment-status/deploy-skill` or `deploy-harness` event for v4.04, which is the standard's defined `N/A` condition rather than a missing measurement. **This row is a stronger instance of the gap than its three predecessors:** v4.01, v4.02 and v4.03 each recorded `N/A` on releases that ran **no** deploy at all, so the field was vacuous; this release ran a real Phase B4 `deploy.sh --deploy` that copied a skill, a references tree, an injected canonical and a package to two targets, and the field is *still* `N/A` because nothing in the deploy path emits `deployment-status`. The gap is filed as #4215.
**Velocity:** planned 22 pts / delivered 22 pts (1.00); files-changed 28; allocation 0/22/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v4.04 --milestone 307 --merge-sha 838ae31485a6`). **The tool's reading is authoritative as taken, unlike its three predecessors' — and the reason is structural, not luck.** v3.97, v4.0, v4.01 and v4.03 each had to correct or derive `delivered` because `**Velocity:**` lands in the Stage-13 chore PR, which by the codified sequencing merges BEFORE the D-1 manual issue-close — so a read taken there returns `delivered 0` while the slices are still open. Here all **6** delivery slices were auto-closed by the release PR's own close keywords at Stage 12, so they were already `closed` when this field was computed and no derivation was needed. Planned and delivered agree at 22 because the six slices are the whole sized membership — #4208 `size:M` 4 · #4183 `size:S` 2 · #4177 `size:S` 2 · #3833 `size:S` 2 · #4178 `size:L` 8 · #4169 `size:M` 4 — which is also the release plan's own 22 effective pts; the five open stage sub-tasks carry no `size:*` label and contribute 0 to both sides. **Allocation reads 0/22/0 — wholly debt — and here that is a work-class claim rather than the mapping gap #4223 records.** Four slices carry `type:bug` and route to debt directly; #4208 (bare `improvement`) and #4177 (`type:task`) fall to the conservative default, and the default is *correct* for both — every slice in this release repairs a verification instrument rather than adding capability. This is the first release since #4223 was filed where the debt bucket is defensible on the merits rather than an artifact of an unrecognised feature label.
**Result:** SUCCESS — release PR #4334 merged to main via a true two-parent merge commit; `v4.04` signed-annotated tag valid and verified at the merge SHA on **both** surfaces (local `git tag -v` and GitHub API `verification.verified = true`), and present on origin at `refs/tags/v4.04`. CI **48/48 SUCCESS** on the live head `df6a9289` under a whole-population check-runs probe with zero non-success conclusions; all **33 branch commits signature-verified** (`verified = 33 of 33`, zero `false` under a whole-population API probe). All **6 delivery issues auto-closed** by the release PR's close keywords. **Phase B4 deploy — `deploy.sh --deploy tracker-manager` — SUCCESS**: 1 skill, 1 references file, 1 package, and the `TEMPLATE_SYNC_MAP` injection of the canonical `tracker-schemas.md`, landed at both the install path and the user-local mirror (identical 82,099-byte file at each). Verified by re-running `deploy.sh --check` and comparing against a pre-deploy baseline under a whole-population probe with a control: `DRIFT:` lines naming `tracker-manager` went **6 → 0** (two of them Check 13's `missing at INSTALL_PATH` / `missing at USER_LOCAL` pair, the rest from Checks 1, 5 and 12), the `canonical-citation-unresolvable-in-package` finding went **1 → 0**, and the whole-population `DRIFT:` count went **200 → 194** — a delta of exactly the six cleared lines, with 194 remaining as the control proving the probe still has power and did not simply stop reporting. Zero `FAIL:` lines in either run. The residual 194 are pre-existing operator-instance drift across other skills, untouched by this release and out of its scope. **Two warn-mode findings from this release's own new instrument are recorded, not suppressed:** Check 13b now emits `complementary-pair-shared-section-divergence` for `## Tracker 1: Daily Status Log` and `## Tracker 3: Open Meetings Tracker`, both declared SHARED in the registry #4178 ships but differing between the canonical and the skill-local copy. They are source-side and therefore unaffected by any deploy — the newly-shipped check doing exactly its job on its first run against real content, and a genuine reconciliation item for intake. The `v4.x` tag population on origin reads `v4.0`, `v4.01`, `v4.02`, `v4.03`, `v4.04` — **monotonic, zero orphans**; two slots were lost to concurrent siblings before the claim and **zero re-versions occurred at or after it**. Zero force pushes, zero history rewrites, zero signature bypasses, zero `--admin`.
**Outcome:** SUCCESS — **ATTAINED** against the Release Outcome Statement (QC4-06). The Statement's AFTER required six things and post-deploy `main` exhibits all six, each with a verifiable anchor: no existence-only stand-in (Check 45(b) now asserts fixed-string containment of the entry's `name`; 9/9 register pins pass, ±1-shift controls score 0/9); no exit-0-on-STALE (`cmd_check_package_freshness` maps `FRESH→0` / `STALE`+non-enforce`→2` / `STALE`+enforce`→1` / unexpected`→1`); no nondeterministic counter (Check 31 reports Class L 93 / Class V 9 across 220 files, identical run-to-run, against an independent 164/26 marker census); no divergence a check cannot see (Check 13b now emits on the canonical↔skill-local pair, and is emitting on two genuinely-divergent shared sections right now); every declared fail-closed check names its runner (`gate-efficacy-standard.md` Requirement (b) admits prose-declared normative predicates as a third class, and the Stage-9 NO-GO remediation closed the two escapes QA found in it); and the audit instrument measures what the shipped rules require (#4169, operator-attested). Routed **(C) accept-as-residual** for the one criterion that cannot be observed here — #4169's load-bearing AC is verified downstream by the Round-2 re-run it gates, outside this release.
**Close-Class-Telemetry:** **NOT EMITTED — mandated mechanism halted.** `compute-close-class-telemetry.sh v4.04 --milestone 307` aborts at its Indicator-6 path with `/usr/bin/python3: Argument list too long`. Root cause measured, not guessed: `count_subtask_evidence()` passes the whole `gh issue list --json number,title,state,comments` payload as a single `argv[1]`, and for this milestone that payload is **1,098,975 bytes** against a system `ARG_MAX` of **1,048,576** — it exceeds the limit by ~50 KB, so the tool cannot run on any milestone whose sub-task comment volume crosses that bound. The failure is fatal to the whole script, so no indicator is produced, not merely Indicator 6. **No value is hand-computed in its place:** emitting numbers under a `mechanism: compute-close-class-telemetry.sh` label that the mechanism did not produce would be exactly the declaration-vs-behavior divergence this release exists to eliminate, and the standing rule is that a broken locked control is repaired through a governed bug and PR rather than worked around in the release that trips over it. Recorded as a close-out finding for intake. Note the shape: this is the **third** consecutive release to hand-emit this field because no close-out tool produces it and no check asserts it (#4329) — and the first where the mandated tool is not merely absent from the close path but unable to execute at all.

#### Release Learnings v4.04

**Synthesized at:** 2026-08-01T12:14:16Z
**Source events:** 1 `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: version=`v4.04`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-08-01T12:14:12Z`

**Surprise:** a counter stable at 45 every sample was over-reporting 5x deterministically - stability was the tell, not a control
**Would-change:** census a stable counter before scoping it out beside a flaky sibling
**Watch-for:** three mandated close-out fields have no producer and no gate

#### Deployment Log v4.03
**Files deployed:** closeout-output-set-integrity — one release PR #4333 (`release/closeout-output-set-integrity → main`, merge-commit `2adf533e`), 5 delivery slices on one branch, 23 commits, 24 files (+3550/−78). The release's unifying property is **artifacts that misdescribe their own enforcement** — a gate that reports on a population it never evaluates, a ledger set that omits a release it claims to index, and a checker whose green means "did not run" rather than "passed". **#4176** (`size:S`) arms the close-completeness gate: `CLOSE_COMPLETENESS_CHECK_CUTOFF` had **no committed carrier anywhere in the repo** — an environment variable nothing set — so Check 48 had been evaluating **dormant since it shipped**, returning a green that meant nothing. Per **D-E** the carrier is now a committed default in `core/deploy/deploy.sh` at cutoff `v3.89`, and the arming change records the *resolved* row count and *resolved* arm row at runtime so a wrong cutoff surfaces immediately rather than silently scoping the gate to zero rows. **#3727** backfills the complete Stage-13 output-set for `v3.69.1`, a shipped release absent from **all four ledgers**: its `RELEASE_LOG` row plus visible-H4 Deployment Log block, its `CHANGELOG` section, its `RELEASE_INDEX` row with a resolving notes link, its `RELEASE_DIGEST` entry, and the authored `release/releases/notes/v3.69.1_RELEASE_NOTES.md` — moving INDEX/LOG row parity **149/149 → 150/150**. Per **D-J** the notes file is in scope, deliberately: the release-notes standard's File Location clause says a hotfix emits no separate notes file, but both prior patch releases (`v3.65.1`, `v3.73.1`) carry one and every `RELEASE_INDEX` row carries a resolving notes link — the clause is inconsistent with its own corpus, and reconciling it is routed to intake rather than done here. **#3113** (`size:L`) is the release's structural card — close-out reliability and anchor-hygiene hardening consolidated from 13 observations, spanning `release/tools/automated-closeout.sh`, `core/deploy/tools/lint_release_corpus.py`, `release/governance/release-process.md` and `core/schemas/gate-criteria-spec.md`. **#1550** wires automated filled-register production into Stage 13 Close; per **D-G** the producer is a new standalone tool, `release/tools/produce-learnings-register.sh`, chosen over the reuse-first in-script option as a recorded deliberate override. **#2422** makes `automated-closeout.sh --check-paths` record **N/A rather than HARD-FAIL** when the release corpus is operator-instance-absent, shipping under **D-H = (A)+(D)** both a spec anchor — the new `release/references/standards/corpus-home-adapter-constraints.md` — and a red-today regression test, `release/tools/tests/test_corpus_home_tolerance.sh`. **The release's own verification instrument was the last thing fixed, and the finding is worth recording.** Stage-8 QA falsified the tolerance suite's arming rule: it armed on a purely *behavioural* proxy (`fixture A exits 0`), so five distinct non-conforming resolvers — including one that crashed on absence and one degenerate universal acceptor — passed the suite while resolving nothing, and one of those greens actively instructed the operator to harden the very thing that was broken. The arming rule was replaced with a **structural-or-behavioural disjunction** (an instance-resolution vocabulary detector with a comment filter, disjoined with the original behavioural limb) plus new assertions R4/R7 that require a **per-corpus-path resolution record** rather than an exit code alone. All five falsifications now exit 1 naming the violated constraint; **0 of 5 remain green**, and the fix was itself mutation-tested at 20 mutants / 22 rows with **zero survivors**. The governing standard was reconciled in the same change rather than annotated — its §5 had documented the old `a == 0` rule verbatim, so fixing the mechanism without it would have shipped a standard that misdescribes its own enforcement, inside a milestone whose subject is exactly that failure class.
**Mechanism:** git merge-commit (PR #4333 → main at `2adf533e1a2f9d3c55be81d86d959718ca53e60e`; a true **two-parent** merge commit — parents `93023d8e` (main) and `c25d6ff8` (release head) — so the plan's declared `git revert -m 1` rollback form applies). **Plain `gh pr merge --merge`; no `--admin`, no signature bypass, zero force pushes, zero history rewrites.** No merge strategy was declared in the plan, so Phase A.4.1's `--merge` default applied — independently required here, since a squash would have produced a single-parent commit and silently invalidated the release's own documented `-m 1` rollback. Phase A.4.2 recorded the allowed-strategies map (`merge:true`, `squash:true`, `rebase:true`) for the audit trail. Signed-annotated tag `v4.03` at the merge SHA (annotated tag object `0c77545fbdc09fadb2d12508103459bb68d38c20`, object type `tag` not `commit`; `git tag -v v4.03` → *Good signature*, ED25519 key `SHA256:/2bw1mPVjUqzNzdOzeS5sDV2DmwczAS1g7NZiFxbjq8`; GitHub API `verification.verified = true`, `reason = valid`; tagger `271413202+cody-hutson@users.noreply.github.com`). Claim bound at the Stage-12 **atomic ref-CAS** via `claim-version.sh --sha 2adf533e1a2f --bump minor` — **first-attempt win, zero CAS collisions, zero signing bypasses**. The default tag message was used deliberately rather than a structured `--message`: the default interpolates `${tag}` and therefore **recomputes correctly on a CAS retry**, whereas a static `--message` carrying a hardcoded version would have been *wrong* on collision — a live risk in this release (see below), not a hypothetical. Bump-class `minor` derives from the Bump-Class Selection Guide (protocol-text modification + reference-document addition; no new skill, no new governance file, no skill behavioural change). **This release carried no pre-claim version token at all** — slug-only plan file, slug-only branch, per **D-Version** and ADR-092 — so the Phase A.5.6 stale-carried-label divergence class it exists to detect is **structurally inapplicable** here rather than merely passing: there was no label that could go stale. **ADR-092's claim-time stamp did not fire, deliberately.** The rename-on-CAS-win is gated on `--stamp-slug`, which is absent for every existing caller; ADR-092 is `status: Proposed` and release-scoped to a different milestone, so the plan file lands and stays at its slug-only name `release/releases/plans/closeout-output-set-integrity_RELEASE_PLAN.md`. **The version slot was genuinely contested at claim time, and the contest was invisible to the freeness oracle.** Pre-merge re-verification ran **four arms**, not three. The three *literal* arms `claimed_set()` evaluates all agreed the anchor was `v4.02` and next-free was `v4.03` — origin signed tags (`v4.0`, `v4.01`, `v4.02`; 0 rows at `v4.03`), published Releases (highest `v4.02`, published `2026-07-31T21:19:07Z`; 0 at `v4.03`), and the `RELEASE_LOG` ledger read from `origin/main` under a whole-population structural probe returning **0 `DEPLOYED` rows against a `VERIFIED` control of 150** — and the adapter's own `--dry-run` independently recomputed `v4.03`, agreeing with the manual read. **The fourth arm disagreed.** Read from **plan-file names, not branch names** — the method distinction that matters, because branch naming is demonstrably inconsistent — the in-flight surface showed `release/check-enforcement-fidelity` carrying `release/releases/plans/v4.03_check-enforcement-fidelity_RELEASE_PLAN.md` with its PR #4334 retitled `release(v4.03)`, open and CLEAN. A sibling release had **stamped `v4.03` into a plan filename three stages before the arbitrating mechanism runs**, and `claimed_set()` cannot see it: a pushed release branch carrying a version-titled plan is a *recorded but unsettled* claim, and none of the three settled-claim surfaces reports it. The contest was resolved **mechanically, by the compare-and-swap, in merge order** — exactly as `ship-order = merge-order = tag-order` requires — rather than by an operator gate or a courtesy skip. This release merged first, pushed the signed tag first, and took the slot; the sibling's claim will return `COLLISION` at its own Phase B3 and recompute upward. **No version gap was created, and no claim was overwritten** (`atomic_claim` has no force path). Recorded because it is the second live instance of this class in one milestone and the reason the release carries no version token in the first place. Phase A.5.1 divergence was **0 commits** (merge-base `93023d8e` equalled `origin/main`), so no pre-merge integration merge was needed; Phase B0 enumerated **0 dependent PRs**; Phase A.7 read `isDraft = false`. Phase B4 required no `deploy.sh --deploy` run — **no skill source changed in this release**, so there is no S-2 copy and no `.skill` rebuild, and Phase J.5's rebuilt-package diff is correspondingly empty. One Layer-2 deploy obligation **is** outstanding and is carried forward, not silently dropped: `core/config/allowlists/script-execution-allowlist.txt` gained `produce-learnings-register.sh`, and hooks read the **token-resolved deployed** allowlist rather than the source, so the operator-instance `deploy.sh --deploy` must run before the next close-out or that close-out hits `BLOCK-DESTRUCTIVE-022`. This is the F3 residual accepted at the Stage-9 GO and is handed to Stage 13.
**Timestamp:** 2026-08-01 (release merge 2026-08-01T09:32:34Z UTC; signed-annotated tag `v4.03` at the merge SHA, tagger 2026-08-01T04:36:44-05:00; operator-local deploy date Saturday 2026-08-01)
**Cycle-Time:** N/A — (T_GO=n/a; T_DEPLOY=n/a; mechanism: compute-cycle-time.sh) — the tool reports no `gate-outcome/plan-review-go` and no `deployment-status/deploy-skill` or `deploy-harness` event for v4.03, which is the standard's defined `N/A` condition rather than a missing measurement. Nothing in the pipeline currently emits `deployment-status` at all, so this field is structurally `N/A` log-wide; the gap is filed as #4215.
**Velocity:** planned 20 pts / delivered 20 pts (1.00); files-changed 24; allocation 0/20/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v4.03 --milestone 304 --merge-sha 2adf533e1a2f`). **Derivation disclosed, because the tool cannot be authoritative at the moment this field must be written.** `**Velocity:**` lands in the Stage-13 chore PR, which by the codified sequencing merges BEFORE milestone close and BEFORE the D-1 manual issue-close — so a tool read taken here returns `delivered 0 pts (0.00); allocation 0/0/0` purely because all five slices are still open, and that is what it literally returned at this run. `planned 20`, `files-changed 24` and `class novel` are the tool's own output and are authoritative as read. `delivered` and `allocation` are derived from the membership disposition, which is fully determined at this point: all five slices close at this close-out and **zero** are deferred, so delivered == planned == 20; the § 4 work-class map resolves all five to **debt** (`#3727` on its `bug` label; `#4176`, `#3113`, `#2422`, `#1550` on the default-to-debt rule — `cluster: automation` is not a debt-list cluster and none carries a feature or protocol signal), giving 0/20/0. Re-verified post-close by re-running the tool; the recorded value is the verified one. The same ordering conflict is why `**Velocity:**` is absent from every v4.02-and-earlier block — the close-out script emits it on no path (#4329).
**Result:** SUCCESS — release PR #4333 merged to main via a true two-parent merge commit; `v4.03` signed-annotated tag valid and verified at the merge SHA on **both** surfaces (local `git tag -v` and GitHub API `verification.verified = true`), and present on origin at `refs/tags/v4.03`. CI **45/45 SUCCESS** on the live head `c25d6ff8` at the merge instant under a whole-population probe with zero non-success checks; all **23 branch commits signature-verified** (`verified = 23 of 23`, zero `false` under a whole-population API probe). Nothing auto-closed — all **5 parent issues remain OPEN** by design, since this release's Closure Phrasing routes issue closure to the Stage-13 automated close-out path rather than to release-PR auto-close keywords. The `v4.x` tag population on origin reads `v4.0`, `v4.01`, `v4.02`, `v4.03` — **monotonic, zero orphans, zero re-versions this release**. Zero force pushes, zero history rewrites, zero signature bypasses, zero `--admin`.
**Outcome:** PARTIAL
**Outcome rationale:** PARTIALLY-ATTAINED per QC4-06: three of four Outcome-Statement clauses fully attained, but the fourth (accumulated anchor-hygiene defects cleared) is attained as mechanism only — the four stale anchor references and the v3.80 tagger identity ship EXEMPTED by operator scope-carve-out and are tracked as #4337 / #4338, so the defects are guarded, not cleared. Disposition: accept-as-residual.
**Close-Class-Telemetry:** retro-conformance 10/10 (1.00); lessons-population 0/2 (0.00); carry-forward-closure N/A — no carry-forward items raised; pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence absent; evidence-preservation 24/24 (1.00); evidence-close-gate N/A; mechanism: compute-close-class-telemetry.sh — **first emission of this field on any row.** The field has been codified and forward-only-mandated since its introducing release merged 2026-06-30, and **zero** of the ~30 post-cutover releases that closed since carry it: no close-out tool produces it and no check asserts it, the same producer/gate gap #4329 records for `**Velocity:**` and the learnings triple. Emitted here by hand from its own mandated tool. `lessons-population 0/2` is honest, not a defect — the producer deliberately never machine-writes the `L<n>` / `A<n>` reflection rows.

#### Release Learnings v4.03

**Synthesized at:** 2026-08-01T11:22:18Z
**Source events:** 1 `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: version=`v4.03`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-08-01T11:22:14Z`

**Surprise:** F3's hook-block never fired - subagent Bash bypasses PreToolUse, so the guard was absent where the close ran
**Would-change:** verify a guard fires where it will execute before accepting it as a GO residual
**Watch-for:** a declared ADR never shipped and no gate compares declared ADDs to the diff

#### Deployment Log v4.02
**Files deployed:** release-closeout-integrity — one release PR #4330 (`release/v4.02-release-closeout-integrity → main`, merge-commit `2822071f`), 7 delivery slices on one branch, 19 commits, 20 files (+2196/−169). The release repairs the **close-out path itself** — the controls that decide whether a release is correctly recorded and correctly versioned — and its unifying property is that every defect it addresses was one a control could not detect about its own operation. **#3724** and **#4339** (both `type:bug`) close two fail-open arms in `release/tools/claim-version.sh`, the script that binds a release to its version at the atomic ref-CAS. In #3724 the published-Releases arm of `claimed_set()` was **silently disabled whenever `CLAIM_REPO` was unset** and the script still exited `0` — so the claim proceeded against a partial view of what was already taken, and reported success. In #4339 `_host_origin_tags` **could not distinguish a failed `git ls-remote` from a genuinely tagless repo**, so a network or auth failure read as "no tags exist" and the allocator computed next-free against an empty set. Both now HALT rather than answer from a partial view; the self-test grew `U-15` (arm-unavailable is not arm-empty), `U-16` (anchor rc-checks) and `U-17` (all three `claimed_set()` arms fail-closed, each with its own detector control). **#3587** and **#3665** (both `type:bug`) repair `release/tools/automated-closeout.sh`: `run_verification` reported the **pre-close issue count** at check 5 — a stale read taken before the closes it was meant to verify, which therefore certified the state it had not yet observed — and `detect_open_issues`' title regex **false-excluded a delivered parent issue whose title merely contained the string 'Stage-13'**, matching on subject matter rather than on the issue's role. **#3701** (`type:bug`) fills **nineteen shipped `CHANGELOG.md` and `RELEASE_DIGEST.md` entries that carried unfilled close-out scaffold placeholders** — published corpus that had been emitted from a template and never completed. **#3718** (`type:task`, `size:L`) is the release's structural card: the release-corpus ledgers had been using **two different date anchors — merge and close-out — with no stated convention**, so a reader could not tell whether two ledgers disagreed or were simply anchored differently. `core/standards/date-variable-convention.md` now declares the anchors explicitly, `RELEASE_LOG` states its merge anchor in a header note, and `release/references/pipeline/stage-13-close.md` declares the close-out anchor for `RELEASE_DIGEST` and `CHANGELOG`; existing rows are **grandfathered, never backfilled** — anchors are declared forward. **#3586** (`type:bug`, `size:XS`) corrects the v3.76 and v3.77 Deployment Logs, which cited milestone `#264` where they meant `#244`. The `release-executor` `.skill` package was rebuilt **in-PR**. **This row is the first written under the merge anchor that #3718 declares** — the release's own close-out is the first consumer of the convention it ships.
**Mechanism:** git merge-commit (PR #4330 → main at `2822071f906d86781f5a66b9ebabe65ccfa2df64`; a true **two-parent** merge commit — parents `c4dde614` (main) and `dac1b15c` (release head) — so the plan's declared `git revert -m 1` rollback form applies). **Plain `gh pr merge --merge`; no `--admin`, no signature bypass, zero force pushes, zero history rewrites.** No merge strategy was declared in the plan, so Phase A.4.1's `--merge` default applied — which is also independently required here, since a squash would have produced a single-parent commit and silently invalidated the release's own documented `-m 1` rollback. Signed-annotated tag `v4.02` at the merge SHA (annotated tag object `182a674f8c125658eaba0285666e0c26ec73c865`, object type `tag` not `commit`; `git tag -v v4.02` → *Good signature*, ED25519 key `SHA256:/2bw1mPVjUqzNzdOzeS5sDV2DmwczAS1g7NZiFxbjq8`; GitHub API `verification.verified = true`, `reason = valid`; tagger `271413202+cody-hutson@users.noreply.github.com`). Claim bound at the Stage-12 **atomic ref-CAS** via `claim-version.sh --sha 2822071f906d --bump minor` — **first-attempt win, zero CAS collisions, zero signing bypasses** — and, per the Stage-8 QA mitigation, run with **`PMO_VERSION_FREENESS_CANDIDATE=v4.02` set explicitly** rather than relying on the bump-class derivation path whose HALT-swallowing behaviour that QA identified; setting the candidate takes resolution order (1) in `_vf_resolve_candidate` and returns before the derivation branch is reached, so the mitigation is structural rather than a matter of the derived value happening to agree. The tool's `--self-test` was run green from a real checkout **before** the claim — **U-0..U-17**, including `U-17` (the three `claimed_set()` fail-open arms **this release closes**) and `U-6`/`U-6b` (never-bypass-signing and its detector negative control) — so the release's own fix was exercised against its own oracle before it was allowed to claim a real version. **Freeness verified pre-merge on four surfaces, each with a discriminating `v4.01` control:** the adapter's `--dry-run` independently recomputed next-free = `v4.02`, equal to the version the branch carried, so no re-version was needed and the Stage-13 re-version ledger has nothing to record; origin signed tags (`v4.02` → 0 rows; control → 1 row); published Releases (`gh release view v4.02` → *release not found*; control → published `2026-07-30T11:58:51Z`); and the `RELEASE_LOG` ledger read from `origin/main` (0 occurrences of `v4.02` and **0** `DEPLOYED`-not-`VERIFIED` in-flight rows, against a `VERIFIED` control of 160; control `v4.01` → 9). `deploy.sh --check-version-freeness` with the explicit candidate returned `v4.02 is free (not in claimed_set) — OK`, and was **falsified against the already-claimed `v4.01`**, which returned `NOT_FREE` — the check discriminates. Its **exit code is `0` on both paths** (lifecycle surface is warn-emit, never-FAIL), so the verdict text is the signal; reading `$?` there would have produced a false PASS. **The first merge attempt was refused and the refusal was transient, not a policy decision** — the Phase A.7 `gh pr ready` transition **re-triggers every workflow subscribed to `ready_for_review`**, which returned 16 checks to `QUEUED` including **five of the nine required contexts**, so protection correctly blocked while they were mid-flight. A `46/46 SUCCESS` read taken seconds after the flip had **raced the re-trigger** and observed only the pre-flip population. Resolution was to poll to completion (~2 min, all 16 green) and re-run **the same plain command**, which then succeeded — not to reach for `--admin`, which would have merged a release with five required gates still running. **ADR-092 claim-time stamp did not fire and correctly so:** the plan is already at its versioned name `release/releases/plans/v4.02-release-closeout-integrity_RELEASE_PLAN.md` with **zero** surviving `{{RELEASE_VERSION}}` tokens (every repo-wide hit is a spec or template *describing* the token), so `--stamp-slug` was deliberately omitted. Phase B4 required no `deploy.sh --deploy` run — the one affected package was rebuilt in-PR, verified by reading the **verdict text** of `deploy.sh --check-package-freshness`, not its exit code: `package-freshness: 54 rostered skill package(s) content-fresh — OK` — so Phase J.5's rebuilt-package diff against the primary is correspondingly **empty**.
**Timestamp:** 2026-07-31 (release merge 2026-07-31T20:48:27Z UTC; signed-annotated tag `v4.02` at the merge SHA, tagger 2026-07-31T20:50:26Z UTC; operator-local deploy date Friday 2026-07-31)
**Cycle-Time:** N/A — (T_GO=n/a; T_DEPLOY=n/a; mechanism: compute-cycle-time.sh) — the tool reports no `gate-outcome/plan-review-go` and no `deployment-status/deploy-skill` or `deploy-harness` event for v4.02, which is the standard's defined `N/A` condition rather than a missing measurement. Nothing in the pipeline currently emits `deployment-status` at all, so this field is structurally `N/A` log-wide; the gap is filed as #4215.
**Result:** SUCCESS — release PR #4330 merged to main via a true two-parent merge commit; `v4.02` signed-annotated tag valid and verified at the merge SHA on **both** surfaces (local `git tag -v` and GitHub API `verification.verified = true`); CI **62/62 SUCCESS** on the live head `dac1b15c` at the merge instant under a whole-population probe with a non-success control returning zero (46 original checks plus the 16 re-triggered by the draft→ready transition). All **19 branch commits signature-verified** (`verified=19 of 19`, zero `false` under a whole-population API probe); **0** unresolved review threads; all **9 required contexts present and passing**. The `v4.x` tag population on origin reads `v4.0`, `v4.01`, `v4.02` — **monotonic, zero orphans, zero re-versions this release**. Zero force pushes, zero history rewrites, zero signature bypasses, zero `--admin`.
**Outcome:** SUCCESS

#### Deployment Log v4.01
**Files deployed:** decision-audit-and-learning (novel class) — one release PR #4167 (`release/v3.97-decision-audit-and-learning → main`, merge-commit `66c5fb26`), 2 delivery slices (#4024 `size:S`, #3705 `size:M`) on one branch, 11 commits, 24 files (+1774/−78). The release ships the **retrospective** half of decision governance, complementing the forward per-decision gates that hold one decision at a time and are structurally blind to a failure mode that fires once in each of several releases. **#4024** (spike) renders the host decision and records it: `core/ADRs/ADR-103-decision-audit-host-qa-auditor-mode-j.md` places the decision-audit capability as **`pmo-qa-auditor` Mode J (Decision-Health Audit)**, a sibling to Mode I rather than a net-new Specialist, on the ground that ADR-019's skill-boundary test requires all three conjuncts and **conjunct 3 (distinct primary role) fails** — Mode J and Mode I occupy the same primary role (retrospective cross-release audit against corpus-defined oracles emitting the review-discipline six-deliverable set) — so the standalone skill is non-conformant by rule, not merely costlier. The mode lands as a dispatcher in `core/skills/pmo-qa-auditor/SKILL.md` plus its machinery in `references/decision-audit-mode-spec.md` and `references/sampling-and-trigger.md`, with the recurring-invocation contract in `release/references/protocols/decision-audit-cadence.md` and the four-to-five-audit cadence cascade applied across the four sibling protocols (`architecture-conformance-cadence.md`, `process-fitness-cadence.md`, `structural-audit-cadence.md`, `platform-health-audit-framework.md`). Three constraints are stated in the mode body rather than left to the spec: the **oracle set is derived and pinned per run, never hardcoded**, and its derivation runs a bounding control asserting the section-scoped count is strictly less than the whole-file count for at least one source — otherwise the probe has degenerated to a file-wide match and the run reports `INDETERMINATE` rather than proceeding on an unbounded probe; **a seam with zero evidence rows reports `no-evidence`, never a passing grade**, because no rows is indistinguishable from no failures unless the distinction is stated, and a coverage index computed over a partly-blind stream otherwise reads as health when it is measuring silence; and the **window orders by merge anchor, never by version number**. **#3705** (bug) closes a control that could never fire: the `session-retro` `Stop` hook was unable to trigger at a session boundary **under any shipped setting**. Two defects, both closed in `core/hooks/session-retro-trigger.sh`. The `Stop` payload is now **pinned against the live harness contract** at `core/hooks/tests/fixtures/stop-payload.json` — it carries `session_id` / `transcript_path` / `cwd` / `permission_mode` / `hook_event_name` / `stop_hook_active` / `last_assistant_message`, and **has never carried `tool_call_count` or `turn_count`**, the invented counters the predicate had been reading. Sampling now reads the **transcript the payload points at**: `tool_calls` = `"type":"tool_use"` occurrences and `turns` = distinct `requestId` — deliberately **not** assistant-entry count, because Claude Code writes one JSONL entry per content block, so assistant entries run ~2.9× true turns (measured: median 188 entries vs 61 `requestId`s) and would fire ~3× earlier than `min_turns` reads. The single sentinel is **split**: `fired/<session_id>` is written on the FIRE path only, before the decision, and the skip path writes **nothing**, so the predicate is re-evaluated as the session grows instead of frozen at turn 1; the native `stop_hook_active` re-entry guard replaces the platform's hand-rolled one. `enforce` **degrades to warn** (recording `warn-window-unsatisfied`) until the verdict log holds a would-fire row — degrade rather than refuse, because a refusal that emits nothing is indistinguishable from the bug being fixed. `--self-test` drives the **real** script across the issue's own 3/1 → 9/3 → 40/12 → 95/28 sequence against a real growing transcript, with a negative control asserting the fixture carries no counter keys, and was verified to have power to fail. The supporting surfaces move with it: `core/config/operator.toml.template`, `release/references/standards/pipeline-event-log-schema.md`, `release/tools/append-pipeline-event.sh` (+174), `release/tools/synthesize-release-learnings.sh` (+114), and `core/ADRs/ADR-087-stop-hook-agent-loop-re-entry-class.md`. Both `.skill` packages (`pmo-qa-auditor`, `session-retro`) were rebuilt **in-PR**.
**Mechanism:** git **squash** merge — PR #4167 → main at `66c5fb263a27a810c1edf5820f08c96f426c6e29`, **plain `gh pr merge`, no `--admin` and no signature bypass**. **This is a single-parent commit** (`git rev-list --parents -1` → one parent `d69dfb56`), so the two-parent `git revert -m 1` convention does **not** apply to this release — plain `git revert 66c5fb26` is the rollback form. Recorded as a deviation from the log's prevailing two-parent mechanism rather than left to be inferred from the SHA. **The merge was initially blocked by `required_signatures`** — one commit (the ADR renumber) was unsigned — and was resolved by **re-signing the commit, not by force-merging with `--admin`**: bypassing signature enforcement on the very release whose sibling fix (#4224 / PR #4231) repairs `claim-version.sh`'s never-bypass-signing guard would have been incoherent. All **11 branch commits ended verified** (`verified=11 of 11`, zero `false` under a whole-population API probe), and the merge went through the plain form. Signed-annotated tag `v4.01` at the merge SHA (annotated tag object `b157b5a5dea1bcfd3ad29d1c7d07752fce174dee`, object type `tag` not `commit`; `git tag -v v4.01` → *Good signature*, ED25519 key `SHA256:/2bw1mPVjUqzNzdOzeS5sDV2DmwczAS1g7NZiFxbjq8`; GitHub API `verification.verified = true`, `reason = valid`). Unique claim bound at the Stage-12 **atomic ref-CAS** via `claim-version.sh --sha 66c5fb263a --bump minor` — **first-attempt win, zero CAS collisions, zero signing bypasses**, and the tool's `--self-test` was run green (U-0..U-13, including the `never-bypass-signing` case U-6 and its detector negative control U-6b) from a real checkout before the claim. **Freeness re-verified at the claim instant on three authoritative surfaces, each with a discriminating `v4.0` control probe:** origin signed tags (`git ls-remote --tags origin refs/tags/v4.01` → 0 rows; control `v4.0` → 1 row), the `RELEASE_LOG` ledger read from `origin/main` (0 occurrences of `v4.01`; **0** `DEPLOYED`-not-`VERIFIED` in-flight rows against a `VERIFIED` control of 159; control `v4.0` → 3), and published Releases (`gh release view v4.01` → *release not found*; control `v4.0` → published `2026-07-29T10:19:05Z`). The adapter's own `--dry-run` independently recomputed next-free = `v4.01`, equal to the version the merge commit carried, so no re-version was needed at the claim. **The open-PR and remote `release/*` branch populations were both 0** at probe time — a transiently-empty population, pinned to baseline `origin/main @ 66c5fb263a` on 2026-07-30, so no claim above rests on that emptiness alone. **ADR-092 claim-time stamp did not fire and correctly so:** the plan was already at its versioned home `release/releases/plans/v4.01_decision-audit-and-learning_RELEASE_PLAN.md` with **zero** `{{RELEASE_VERSION}}` tokens surviving in the merged tree, so `--stamp-slug` was deliberately omitted. Phase B4 required no `deploy.sh --deploy` run — both packages were rebuilt in-PR, verified by a direct run of `deploy.sh --check-package-freshness` reading its **verdict text**, not its exit code: `package-freshness: 54 rostered skill package(s) content-fresh — OK` — so **AI-013 did not fire** and Phase J.5's rebuilt-package diff is correspondingly empty.
**Timestamp:** 2026-07-30 (release merge 2026-07-30T11:15:01Z UTC; signed-annotated tag `v4.01` at the merge SHA, tagger 2026-07-30T11:21:55Z UTC; operator-local deploy date Thursday 2026-07-30)
**Cycle-Time:** N/A — (T_GO=n/a; T_DEPLOY=n/a; mechanism: compute-cycle-time.sh) — the tool reports no `deployment-status/deploy-skill` or `deploy-harness` event for v4.01, which is the standard's defined `N/A` condition rather than a missing measurement. Nothing in the pipeline currently emits `deployment-status` at all, so this field is structurally `N/A` log-wide; the gap is filed as #4215.
**Velocity:** planned **6** pts / delivered **6** pts (**1.00**); files-changed 24; allocation 0/6/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v4.01 --milestone 296 --merge-sha 66c5fb263a`; computed at Stage 13 **after** the D-1 manual close transitioned both delivery slices to closed, so *delivered* is authoritative — a read taken while they were open returns delivered 0). Planned and delivered agree because the two delivery slices are the whole of the closing membership: #4024 `size:S` = 2 pts and #3705 `size:M` = 4 pts. **The figure is authoritative only because the nine parked Partition-B members were de-milestoned first** at the Phase A2 deferred-item disposition — #4027 (`size:L` = 8) and #4028 (`size:S` = 2) plus their seven stage sub-tasks would otherwise have inflated *planned* to 16 against a delivered 6, reading 0.38 for work that was never in this release's scope. **Allocation reads 0/6/0 — wholly debt — and that is a mapping gap, not a work-class claim:** neither `type:spike` (#4024) nor `type:bug` (#3705) carries a label the work-class map recognises as a feature signal, the fourth consecutive release to record this independently (v3.98, v3.100, v4.0), filed as #4223.
**Result:** SUCCESS — release PR #4167 merged to main; `v4.01` signed-annotated tag valid and verified at the merge SHA on both surfaces (local `git tag -v` and GitHub `verification.verified = true`); CI **45/45 success** on the live PR head `939bd981` at the merge instant under a whole-population probe with a non-success control returning zero, and **28/28 success** on the merge commit itself. Zero force pushes, zero history rewrites, zero signature bypasses. The **re-version history is forward-only and monotonic at every step: `v3.97 → v3.101 → v4.01`** — `v3.97` was claimed mid-park by the sibling `build-philosophy-corpus` (PR #4133) while this branch was parked awaiting milestone #295, `v3.101` was then superseded when the sibling `agent-finops-intelligence` took the operator-decided major bump to `v4.0` and moved the anchor past it, and the final `v4.01` form (padded, matching the governed `claim-version.sh` output and the `v2.00`–`v2.09` rollover precedent) was **operator-rendered** on a genuine ambiguity that a prior re-version spoke had correctly HALTED on rather than guessed. **No tag was ever cut for `v3.101`** (`git ls-remote --tags origin refs/tags/v3.101` → 0 rows, so no orphan), and `v3.97` belongs to its rightful claimant. Mainline carries the known pre-existing `deploy.sh --check` Check 47 `release-body-drift` finding on already-published Releases, owned upstream; this release introduced no new FAIL and attempted no remediation of it.
**Outcome:** PARTIAL
**Outcome rationale:** PARTIALLY-ATTAINED against the milestone Release Outcome Statement (QC4-06): the learning-loop clause is delivered — session-retro can now fire at a real threshold crossing, with the hook shipping inert — but the repeatable decision health-check and its J1-J7 coverage scorecard are NOT delivered; only the host is decided (ADR-103, pmo-qa-auditor Mode J). Delivery itself was clean: 2/2 issues accepted at Stage 8 (#4024 ACCEPT 2/2; #3705 CONDITIONAL with PA-4 and PA-6 carried PARTIAL deliberately), signed tag verified on both surfaces, zero signature bypasses. The undelivered clause is deferred with its unpark gate now met on two of three conjuncts, not waived.

#### Release Learnings v4.01

**Synthesized at:** 2026-07-30T11:52:20Z
**Source events:** 1 `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: version=`v4.01`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-07-30T11:51:09Z`

**Surprise:** write gate covers 1 of 94 separators; 63 DESTROY a real cluster, only 30 inflate one
**Would-change:** write regression ACs against the failure class over its whole input population, not one exemplar
**Watch-for:** Check 61 join hangs on ONE slug-keyed row; PA-6 warn window self-satisfies

#### Deployment Log v4.0

**Velocity:** planned **28** pts / delivered **28** pts (**1.00**); files-changed 50; allocation 0/28/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v4.0 --milestone 293 --merge-sha 20894ba6`; computed at Stage 13 **after** the D-1 manual close transitioned all eight delivery slices to closed, so delivered is authoritative — a read taken while they were open returns delivered 0, the failure mode v3.97's close recorded). **The raw tool output reads planned 36; the figure recorded here is corrected to 28, and the divergence is stated rather than absorbed.** The tool sums `size:*` over *all* milestone members, and two members are not delivery scope: **#4206** and **#4207** (`size:M`, 4 pts each) are accepted-limitation follow-ups **filed during this release against the estimator it ships**, deliberately left open at close and deliberately left on the milestone so their provenance is preserved. The eight delivery slices sum to exactly 28 — #4044 `size:S` 2 · #4043 `size:M` 4 · #3911 `size:M` 4 · #3912 `size:M` 4 · #3610 `size:M` 4 · #3611 `size:M` 4 · #3612 `size:M` 4 · #3613 `size:S` 2 — which is also the release plan's own 28 raw pts, and the tool's *delivered* figure independently reads 28 because only closed members count. Planned and delivered therefore agree at 28 for a ratio of **1.00**, not the raw 0.78. **Correction to the pre-close attribution, recorded because the reason differs from the figure:** the divergence was expected to come from parent epic #3329 (`type:epic`, `size:L` = 8 pts) being counted alongside its own four child slices. That mechanism is **stale** — #3329 was milestoned on 2026-07-25T04:42:46Z and **demilestoned on 2026-07-27T23:28:34Z**, two days before the merge, and does not appear in the milestone's membership at close (`gh issue view 3329 --json milestone` → none; confirmed against the issue's own `milestoned`/`demilestoned` timeline events and the full membership listing). The arithmetic is coincidentally identical — `size:L` = 8 and `#4206 + #4207` = 4 + 4 = 8 — so 28 is the right figure either way, but the recorded cause is the follow-up pair, not the epic. **Allocation reads 0/28/0** — wholly debt — because none of the eight slices carries a label the work-class map recognises as a feature signal (`type:task` ×4, `type:story` ×2, bare `improvement` ×2). Six of the eight deliver net-new operator-facing capability, so the bucket is a **mapping gap, not a work-class claim** — the same finding v3.98 and v3.100 each recorded independently, now filed as #4223.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v4.md)_

#### Deployment Log v3.100

**Velocity:** planned 20 pts / delivered 20 pts (1.00); files-changed 32; allocation 0/20/0 pts (feature/debt/protocol-slack); class cross-cutting (mechanism: `compute-release-velocity.sh v3.100 --milestone 295 --merge-sha 35f71ae7`; computed at Stage 13 with all six delivery slices already closed by the release PR, so delivered is authoritative. **Allocation reads 0/20/0 despite a 3-bug / 3-story membership split** — the three `type:bug` slices (#4051 `size:S`, #3712 `size:S`, #3704 `size:M`) map to debt directly, and the three `type:story` slices (#4026, #4025, #3723, all `size:M`) carry `improvement` rather than `enhancement` / `type:feature`, which the label→work-class map does not recognise as a feature signal, so they fall to the conservative debt default. The **bucket** is defensible on the merits — all six slices repair the pipeline's own instrumentation and self-checking surfaces rather than adding user-facing capability — but the **route** is a mapping gap, not a work-class claim: an `improvement`-labelled story cannot currently register as feature allocation. Recorded here rather than silently accepted; same class of finding as v3.98's `type:story` artifact.)

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.99

**Velocity:** planned 6 pts / delivered 6 pts (1.00); files-changed 5; allocation 0/6/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v3.99 --milestone 294 --merge-sha 3f8af4a7`; computed at Stage 13 **after** the D-1 manual close transitioned #4020 and #4021 to closed, so delivered is authoritative — a read taken while both were open would have returned delivered 0, the failure mode v3.97's close recorded. **Allocation reads 0/6/0 because both members carry `type:bug`**, which the label→work-class map routes to debt; that is the correct classification here — both slices are conformance defects against the skill's own runtime, not new capability — so unlike v3.98's `type:story` artifact this split is a work-class claim rather than a mapping gap.)

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Release Learnings v3.99

**Synthesized at:** 2026-07-29T01:33:59Z
**Source events:** 1 `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: version=`v3.99`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-07-29T01:33:54Z`
**Surprise:** §3.2 close gate PASSed a wholly unfilled note scaffold (its guidance comment carries the check-9 placeholder)
**Would-change:** author the note BEFORE automated-closeout.sh (its scaffold phase SKIPs when the file already exists, so a pre-authored note is graded as real prose instead of the gate grading a scaffold that passes vacuously)
**Watch-for:** codified Phase outputs the tool has no phase for (B-velocity) — **this is now N=2**: v3.98's close recorded the identical finding independently one hour earlier, so the gap is systemic rather than a one-off. Traced root cause and both candidate fixes are recorded on #3113 (AC-1); the accreting content damage is #3701.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.98

**Velocity:** planned 12 pts / delivered 12 pts (1.00); files-changed 17; allocation 0/12/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v3.98 --milestone 274 --merge-sha 5f8aa26b`; computed at Stage 13 with all three membership issues already closed, so delivered is authoritative on first read — no post-close recompute was needed. **Allocation reads 0/12/0 as a label-map artifact, not a work-class claim:** the map's feature signals are `enhancement` / `type:feature` / `feature`, and none of the three carries one — `type:story` is unmapped, `cluster: architecture` on #2574 / #2575 is an explicit debt signal, and #3327 (`size:M`, `type:story` only) falls to the conservative default. The delivered work is a capability slice, not debt-paydown; the bucket split under-reports feature delivery whenever a release is labelled `type:story` rather than `enhancement`.)

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Release Learnings v3.98

**Synthesized at:** 2026-07-29T01:06:50Z
**Source events:** 1 `release-synthesis/learnings-triple` row(s) from `pipeline-event-log.md` (filter: version=`v3.98`)
**Source-row anchors:** `pipeline-event-log.md` row(s) at ts `2026-07-29T01:06:44Z`
**Surprise:** the `.version` bump was directed SKIPPED on the reading that a later, already-tagged release (v3.99) would be regressed by stamping v3.98. Both governing checks anchor elsewhere: Check 39 anchors the latest **published** GitHub Release (v3.99 is tag-only — `gh release view v3.99` returns *release not found*), and Check 48 anchors the most-recent **VERIFIED** `RELEASE_LOG` row (v3.98 once this close lands). Stamping v3.98 was therefore correct, and skipping it would have *manufactured* a Check 48 finding rather than avoided one.
**Would-change:** treat "a higher version is already tagged" as the prompt to read the two anchors, not as evidence of regression risk. Check 39's own rationale block explicitly rejects tag/semver-max anchoring and names the tagged-but-unpublished-ahead case as the exact situation it refuses to fail — the deciding evidence was already codified and only needed reading.
**Watch-for:** `automated-closeout.sh` emits **neither** the Phase B-velocity `**Velocity:**` field **nor** the Phase A7 learnings triple, though `stage-13-close.md` mandates both in the same Stage 13 chore PR. A pure-script close drops two codified outputs, and Check 48's asserted set does not include either — so the gap is invisible to the standing completeness gate and only surfaces when a closer compares against sibling rows by hand. Also recurring: ADR-099 still reads `status: Proposed` after its Stage 9 ratification gate.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.97

**Velocity:** planned 2 pts / delivered 2 pts (1.00); files-changed 5; allocation 0/2/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v3.97 --milestone 277 --merge-sha c290126c`; recomputed after the Stage-13 D-1 manual close transitioned both membership issues to closed — the first read, taken while both were still open, returned delivered 0. Only #2379 carries a `size:*` label, so planned/delivered count one of the two membership issues; #2601 is unsized and contributes 0 pts to both sides, which is why the ratio is 1.00 rather than a partial).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.96

**Velocity:** planned 16 pts / delivered 16 pts (1.00); files-changed 31; allocation 16/0/0 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v3.96 --milestone 292 --merge-sha ac31eb29`; delivered/allocation reconcile at the Stage-13 milestone parent-close — the 2 in-scope issues #3909 / #3910 are the complete membership, both closing at this Stage 13).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.95

**Velocity:** planned 22 pts / delivered 22 pts (1.00); files-changed 39; allocation 16/4/2 pts (feature/debt/protocol-slack); class novel (mechanism: `compute-release-velocity.sh v3.95 --milestone 183 --merge-sha 67f1c0c5`, recomputed after the Stage-13 Milestone parent-close transitioned the 5 membership issues to Done).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.94

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.93

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.92

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.91

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.90

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.89

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.88

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.87

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log governance-ci-gates

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v3.86

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.85

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.84

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.83

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log governance-ci-checks

**Velocity:** planned 24 pts / delivered 24 pts (1.00) — class cross-cutting; 7 delivery slices; size mix 1×L + 2×M + 4×S; 47 files changed; allocation 2/6/16 pts (feature/debt/protocol-slack); 0 deferred / 0 cut; 6 non-blocking follow-ups filed (#3706, #3707, #3708, #3709, #3710, #3711). Note the planned figure is *current membership sized*: the Stage-4 plan of record was 20 pts across 6 members, and #1490 (M, 4 pts) was retagged in at Stage 9 (mechanism: compute-release-velocity.sh).

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v3.82

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.81

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.80

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.79

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.78

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.77

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.76

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.75

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.74

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.73.1

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.73

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.72

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.71

**Velocity:** planned 28 pts / delivered 28 pts (1.00) — class novel; 4 delivery slices (uniform closed 5-bin scaffold + folder-enum migration · single-inbox intake + extraction · generated provenance + promotion lifecycle · tracker frontmatter + raw→tracked edges); size mix 3×L + 1×M; 46 files changed; 0 deferred / 0 cut; 3 non-blocking fast-follows filed (#3385, #3386, #3387).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.70

**Velocity:** class novel; 5 delivery slices (freshness gate G-PL4 · hub-owned close + ADR-079 · warn-log path fix · self-test hermetic fix); 10 files changed (pipeline/governance/schema docs + 1 tool + 1 ADR); #1686 enforce-flip deferred at Mode R pre-flight (unmet 128-issue G1 backlog, observation #3352); 5 non-blocking follow-up observations filed (#3352, #3354, #3355, #3383, #3388).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.69.1

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.69

**Velocity:** class routine; 4 delivery slices (D-Refs split · governance SSOT · package rebuild · folded-in description fix); files-changed: 3 SKILL.md + OPERATIONS pointer + deploy.sh + blast-radius + 11 tokenized corpus files + 34 rebuilt/new `.skill` package pairs.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.68

**Velocity:** planned 24 pts / delivered 24 pts (1.00); files-changed 15; allocation 4/20/0 pts (feature/debt/protocol-slack); class novel; mechanism: compute-release-velocity.sh (delivered/allocation manually computed from the milestone membership per the standard's manual-fill clause — the tool's live-state run at close predated this same close-out's Stage-13 issue closures; #172 `enhancement` → feature 4; #222/#219 `skill-update` → debt 12; #2226 default → debt 8).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.67

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.66

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.65.1

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.65

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.64

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.63

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.62

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.61

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.60

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.59

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.58

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.57

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.56

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.53

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.52

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.51

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.50

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.49

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.48

**Velocity:** N/A — `compute-release-velocity.sh v3.48 --milestone 254 --merge-sha dd9c284` returns N/A (no `size:*` labels on the milestone membership, so points cannot be derived); files-changed 7 recorded; Release Class **novel** (excluded from the calibration ratio).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.47

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.45

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.44

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.43

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.42

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.41

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.40

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.38

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.37

**Velocity:** N/A — 3 stories carry `size:L` (×2, #362/#363) + `size:M` (×1, #159); no points-scale label model on this milestone, so planned/delivered points N/A. Files-changed: release PR #2676 (+ entity templates + composed-index template + plan-entity schema); no `.skill` package touched. Release Class: novel.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.36

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.35

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.34

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.33

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.32

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.30

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.29

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.28

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.27

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.26

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.24

**Velocity:** 2 build issues (#2115 Mode R, #2212 Mode O); class `novel` (net-new orchestrator skill — the whole-release control plane; the `novel` triggers fire); 9 files changed (additive net-new skill surface — SKILL.md + 4 references + deploy roster + `.skill` package + `.sha256`).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.21

**Velocity:** 3 build issues (#68 size:M, #128 size:M, #432 size:M; raw 12 → ×1.15 novel weight ≈ 14 effective); class `novel`; 8 files changed (additive/corrective; the new ADR-049 + the release plan included).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.22

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v3.23

**Velocity:** planned 16 pts / delivered 16 pts (1.00); files-changed 32; allocation 0/16/0 pts (feature/debt/protocol-slack); class `novel` (#1125 size:L, #1126 size:L; mechanism: compute-release-velocity.sh).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v2.41

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.40

**Velocity:** planned 8 pts / delivered 8 pts (1.00); files-changed 9; allocation 0/4/4 pts (feature/debt/protocol-slack); class routine; mechanism: compute-release-velocity.sh.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.39

**Velocity:** 3 build issues (#167 size:L, #168 size:M, #46 size:M; raw 16 → ×1.15 novel weight = 18 effective, band 15–25, G3-15 PASS); class `novel`; 7 files changed +294/−2.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.38

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.37

**Velocity:** 3 build issues (#2120 size:M, #2082 size:M, #2085 size:M; effective ≈12, under the 15–25 band — accepted per bundle-composition-doctrine § 3 Step 5, capability boundary clear) + 1 absorbed (#1290); class `routine`; files-changed = release-notes-standard.md, stage-12-execute.md, stage-13-close.md, hub-spoke-bridge.md, lint_release_corpus.py, deploy.sh, eval-rubric, ADR-048, the release plan.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.36

**Velocity:** 6 build issues (#500 size:S, #283 size:M, #662 size:S, #280 size:M, #292 size:M, #225 size:M; effective 23, band 15–25, G3-15 PASS); class `novel`; files-changed = 8 source (stage-01/02/06, stage-io-contracts, gate-criteria-spec, release-process, stage-03-bundle, improvement.yml) + 1 new tool + 1 fixture test + 1 skill package + 1 sha256 sidecar + the release plan.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.32

**Velocity:** 3 build issues (#1811 row-currency, #1658 field-currency, #1211 consumer re-point); class `routine`; files-changed = `deploy.sh` (+289 net) + 13 citation-correction files + 2 skill source files (registry.md, pmo-architect/SKILL.md) + 4 skill packages + 4 sha256 sidecars + the release plan.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.31

**Velocity:** 6 build issues (#1073 size:S, #1074 size:L, #1075 size:M, #1076 size:M, #1077 size:L, #249 size:S); class `novel`; files-changed 9 source (+ 2 skill packages + 2 sha256 sidecars + the release plan), additive throughout.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.30

**Velocity:** 3 build issues (#121 size:S, #677, #399) + 2 dispositions (#2081, #2080) + 1 umbrella (#753); class `cross-cutting`; files-changed 30 (+157/−99, incl. the release plan, excl. the release-cut package rebuild).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.29

**Velocity:** 10 cards — #49 #94 #107 #127 #305 #498 #857 #881 #1100 #2095 (all `type:task`, sizes XS–M); class `routine`; files-changed 17 (+374/−509, incl. the release plan, excl. the release-cut package rebuild; the deletion is the #94 single-sourced duplicate).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.28

**Velocity:** 1 card — #205 (task, size:M); class `novel`; files-changed 8 (+120/−8, incl. the release plan, excl. the release-cut package rebuild).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.27

**Velocity:** 3 cards — #436 (staleness-confidence standard + ADR) + #545 (human-informative titles + G1-01 floor) + #211 (ticket information model + Stage column); #229 record-only (closed validation spike, no build); class `cross-cutting`; files-changed 24 (+671/−57, incl. the release plan, excl. the release-cut package rebuild).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.26

**Velocity:** 3 cards — #2040 (task, size:S) + #2041 (task, size:S) + #2042 (story, size:M); class `routine`; files-changed 6 (5 + the release plan). Empty `.skill`-rebuild surface.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.25

**Velocity:** 6 cards — #189 (story, Spoke B) + the Spoke-A bundle #78 / #210 / #879 / #1669 / #31 (one bundled writer); class `novel`; files-changed 17 (+1185/−7, incl. the release plan); mechanism: compute-release-velocity.sh `--milestone 168`. Empty `.skill`-rebuild surface (no SKILL.md edited).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.24

**Velocity:** 10 issues (#77 task size:M relocation hub + #1094 spike size:M + #751 task size:M + #764/#171/#163/#580/#663/#113/#81 size:S); files-changed 52 (incl. the release plan; +1006/−146 across the corpus, excl. the release-cut package rebuild); class `novel`.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.23

**Velocity:** 6 cards — #1897 (spike, size:M) + #315 (story, size:L) + #1166 (story, size:M) + #1898 (story, size:L) + #1899 (story, size:L) + #1900 (task, size:S); planned 34 pts (compute-release-velocity.sh `--milestone 188`); files-changed 18 (+677/−31, incl. the release plan); class `novel`.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.22

**Velocity:** 3 issues (#317 task + #378 story + #56 story size:L, decomposed to a corpus-foundation card); files-changed 27 (+549/−50, incl. 5 rebuilt packages + the release plan); class `novel`.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Release Learnings v2.22

**Surprise:** the milestone entered Stage 4 recorded version-less, but at Stage 5 Collective Review the version-less posture was reconsidered and the release settled on **v2.22 (minor)** — all three cards make material edits to 5 skills whose `version:` field MUST bump to a release tag per `version-field-semantics.md` (a milestone slug is regex-invalid against `^v[0-9]+\.[0-9]+(-[a-z]+)?$`), so there was no valid version-less provision once the skill-bump surface was in scope.
**Would-change:** surface the skill-`version:`-bump implication at the Stage 4 D-Version gate, not at Stage 5 — the deciding fact (5 skills bump, therefore a tag is mandatory) was knowable from the File Change Matrix at planning time; pulling it forward would have settled the version one stage earlier.
**Watch-for:** the **cite-by-path** single-sourcing choice (comms-writer Types 2/3 + `channel-formats.md` + the `MTG-###` field all point at the two new canonical specs rather than carrying inline copies) voids the duplicate-source-discipline drift risk by construction — but it means any future edit to the agenda/recap element set must land in the canonical spec only; an editor who "fixes" the format inline in a consuming skill re-introduces the very duplication this release removed. Also watch the **#56 decompose**: the foundation ships one domain (Estimation) seeded with its consuming skill — the 9 deferred #1173 domains must each preserve that seed-with-consumer floor to avoid an orphaned-corpus maintenance-debt class.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.20

**Velocity:** 9 deliverables (#156, #1155, #154, #1156, #1865, #1866, #202, #208, #752) across 29 commits; files-changed 36 (+2402/−308, incl. the release plan); class `cross-cutting`.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.21

**Velocity:** 3 issues (#337 L + #320 L keystone + #321 M); files-changed 9 (+405/−5, incl. the release plan); class `cross-cutting`.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.19

**Velocity:** 2 issues (#1846 shim + token genericize, #1853 Dual-Framing Bridge single-source); files-changed 12 across 2 commits (9 + 3, `project-schema.md` in both); class cleanup.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.18.1

**Velocity:** 1 story (#1830, P2) delivered; files-changed 14; class `cross-cutting`.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.18

**Velocity:** planned 14 pts / delivered 14 pts (1.00) over the milestone membership (the decouple/genericize bug #1778 L=8 + the Hybrid-Two story #32 M=4, plus the S0 standalone-decouple firebreak S=2 carried within #1778 per bundle-composition-doctrine §3); files-changed ~62; class `cross-cutting`; mechanism: compute-release-velocity.sh against milestone #224.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.17

**Velocity:** planned 16 pts / delivered 16 pts (1.00) over the milestone membership (4 stories — E1 #1764 L=8, E4 #1767 M=4, E2 #1765 S=2, E3 #1766 S=2 per bundle-composition-doctrine §3; the three E1 slices #1774/#1775/#1776 carry no independent points); files-changed 13; class `cross-cutting`; mechanism: compute-release-velocity.sh against milestone #223.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.16

**Velocity:** planned 56 pts / delivered 56 pts (1.00) over the milestone membership (13 of 14 build issues size-labelled — XS=1/S=2/M=4/L=8/XL=16 per bundle-composition-doctrine §3; #950 source-observation unlabelled); files-changed 26; class `cross-cutting`; mechanism: compute-release-velocity.sh against milestone #222, recomputed at Stage 13 post-close.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.15

**Velocity:** N/A — no `size:*` labels on the milestone #216 membership, so delivered points cannot be derived; class `novel` (excluded from the calibration ratio); mechanism: compute-release-velocity.sh against milestone #216, recomputed at Stage 13.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.12

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.14

**Velocity:** N/A — no `size:*` labels on the milestone membership (#164/#165), so delivered points cannot be derived; files-changed 9 recorded; class `novel` (excluded from the calibration ratio); mechanism: compute-release-velocity.sh against milestone #158, recomputed at Stage 13.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log release-version-stamping

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v2.13

**Velocity:** 16 pts delivered (planned 16; ratio 1.00); allocation 0/0/16 feature/debt/protocol-slack; mechanism: compute-release-velocity.sh against milestone #147, recomputed at Stage 13.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.11

**Velocity:** ~55 raw pts (1×L + 7×M + 4×S) across the 12 build issues; mechanism: compute-release-velocity.sh against milestone #214, recomputed at Stage 13.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.10

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.09

**Velocity:** N/A — only 1 of 11 parents carries a `size:*` label (#86 `size:XS`; the other 10 are unsized), so points cannot be derived for the release; files-changed 18 recorded; mechanism: compute-release-velocity.sh against milestone #115, recomputed at Stage 13. Per `release-velocity-tracking.md`, a release without a `size:*`-labelled membership records `Velocity: N/A` (no synthetic points).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.04

**Velocity:** N/A — no `size:*` labels on milestone #154 membership (#1412, #360, #361 are unsized), so points cannot be derived; files-changed 5 recorded; class unknown (excluded from the calibration ratio); mechanism: compute-release-velocity.sh against milestone #154, recomputed at Stage 13. Per `release-velocity-tracking.md`, a release with no `size:*`-labelled membership records `Velocity: N/A` (no synthetic points). The whole release is governance/spec corpus (a design-only ADR + a public template + a `stage-13-close.md` §6 edit), no application logic.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.07

**Velocity:** planned 16 pts / delivered 16 pts (ratio 1.00); files-changed 26; allocation 0/0/16 pts (feature/debt/protocol-slack); class novel (plan-declared; the milestone carries no `release-class:` label, so the tool reports `class unknown`); mechanism: compute-release-velocity.sh against milestone #187, recomputed at Stage 13 after the 6 cards were closed. Only #322 carries a `size:*` label (`size:XL` = 16 pts); the five C1–C5 cards (#1159–#1163) are unsized = 0 pts, so planned = delivered = 16 (1.00). The whole release is governance/spec/config + one hook + a SKILL.md edit (no application logic), so the delivered points map to the protocol-slack work-class.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.08

**Velocity:** planned 26 pts / delivered 26 pts (ratio 1.00); files-changed 12; allocation 0/2/24 pts (feature/debt/protocol-slack); class novel (plan-declared; the milestone carries no `release-class:` label, so the tool reports `class unknown`); mechanism: compute-release-velocity.sh against milestone #195, recomputed at Stage 13 after #334 and #1165 were closed. All four milestone members are closed (#334 size:XL=16, #117 size:L=8, #370 size:S=2, #1165 unsized=0) → delivered = planned (1.00).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.06

**Velocity:** N/A for this row — the operator-instance pipeline event log carries no planned-points/gate-outcome record for milestone #114, so `compute-release-velocity.sh` reports `class unknown` with no plan baseline to compare against; the plan-declared Release Class is `cross-cutting` (the milestone carries no `release-class:` label, so the value embedded here is the plan-declared class). The v2.06.1 hotfix is a deploy-script bug repair (#1475), not a planned-scope member, and is excluded from any velocity baseline.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.03

**Velocity:** planned 12 pts / delivered 12 pts (1.00); files-changed 14; allocation 0/12/0 pts (feature/debt/protocol-slack); class novel; mechanism: compute-release-velocity.sh. v2.03 is the first release to record a measured Velocity field (it enters Stage 13 strictly after the v2.02 introducing merge SHA). Both members closed (#186 size:L = 8 pts, #185 size:M = 4 pts), so delivered = planned (1.00). The allocation maps both `skill-update`-labelled cards to the debt work-class per the label→work-class map in release-velocity-tracking.md §4 (the closed XS/S/M/L/XL point scale and round-half-up ratio mode are taken by reference from bundle-composition-doctrine.md §3 Step 5, not re-derived). The declared Release Class is `novel` (the milestone carries no `release-class:` label, so the tool reported `class unknown`; the value embedded here is the plan-declared class).

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.02

**Velocity:** N/A — v2.02 is the velocity instrument's introducing release and is grandfather-exempt (reflexive-pipeline-loop discipline — a release shipping the velocity convention does not retroactively self-instrument; mechanism: compute-release-velocity.sh). The field is present going-forward only, on releases entering Stage 13 strictly after this introducing merge SHA; v2.02 itself records no measured velocity and is excluded from the calibration population.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.01

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v2.00

_Archived: [segment](RELEASE_LOG_ARCHIVE-v2.md)_

#### Deployment Log v1.24

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.23

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.22

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.21

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log parallel-launch-quota-budget-gate

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v1.20

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.19

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.18

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.17

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.16

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.15

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.14

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.13

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.12

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log cross-reference-integrity-ci

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v1.11

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.10

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.09

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log memory-to-corpus-codification

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v1.08

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.07

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log domain-aware-stage5-design

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v3.20

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v1.06

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log intake-elicitation-skill

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v1.05

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log public-flip-install-blockers

_Archived: [segment](RELEASE_LOG_ARCHIVE-_unversioned.md)_

#### Deployment Log v3.19

_Archived: [segment](RELEASE_LOG_ARCHIVE-v3.md)_

#### Deployment Log v1.04

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.02

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Deployment Log v1.01

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

#### Release Learnings v1.01

**Surprise:** R-A scope expansion adopted at Stage 5 Collective Review (initial scope was the Stage 12 spec only; expanded to scrub all 7 file locations carrying the prior lightweight tag form) — re-classified the release from `routine` to `cross-cutting`. Cheaper-to-stricter transition was correctly applied; per-action signatures already rendered remained valid.
**Would-change:** The `core/CLAUDE.md.template` tier-selection wording sync was logged as Tier 1 out-of-scope drift at Stage 5 (kept under cross-cutting (b) threshold) but emerged as a follow-up Issue at Stage 13. A more aggressive R-A scope expansion at Stage 5 (or a Stage 4 R-A scope audit gate) might have caught the template surface earlier. Net: deferral was correct under the threshold discipline; mechanism for future R-A scope audits could surface template/generator surfaces explicitly.
**Watch-for:** First downstream release after v1.01-intake will be the first consumer of (a) the G-PR8 mid-pipeline divergence check at Stage 9 Phase A6.5, (b) the AC-Drift Handling Protocol verdict enum at Stage 8, and (c) the new `Outcome:` line on the Deployment Log per #218 tracking. Both #105 and #274 carry explicit cutover clauses exempting v1.01-intake itself. If the first downstream release has a clean Stage 9 entry (no concurrent release mid-pipeline) and clean Stage 8 (no drifted ACs), G-PR8 + Drift-protocol firing remains unobserved — empirical validation deferred until a representative test case emerges in production. The reflexive-pipeline-loop discipline is now an established pattern across 3 cutover-clause subjects in a single release; reusable convention for future protocol-shipping releases.

_Archived: [segment](RELEASE_LOG_ARCHIVE-v1.md)_

---
title: Controls — overview
purpose: Counts of controls by mechanism kind and enforcement class, with one view per kind and the control-to-page inversion
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
generated_by: build-process-catalog.py
---

# Controls — overview

373 controls in the controls register. A cell naming one class counts under that class, a qualifier included. A cell naming two classes counts in the Split column. Cited counts the kind's controls that at least one page cites.

| Mechanism kind | code-enforce | code-warn | code-off | prose-only | host-config | not-a-control | Split | Total | Cited | View |
|---|---|---|---|---|---|---|---|---|---|---|
| hook-rule | 33 | 22 | 24 |  |  | 5 |  | 84 | 5 | [hook-rule](controls-hook-rule.md) |
| hook-registration | 5 | 5 | 10 |  |  | 1 | 6 | 27 | 3 | [hook-registration](controls-hook-registration.md) |
| settings-permission | 7 |  |  |  |  |  |  | 7 |  | [settings-permission](controls-settings-permission.md) |
| deploy-check | 18 | 58 |  |  |  | 2 | 5 | 83 | 83 | [deploy-check](controls-deploy-check.md) |
| ci-job | 41 | 13 |  |  |  |  |  | 54 | 22 | [ci-job](controls-ci-job.md) |
| prose-rule | 17 | 12 | 4 | 83 | 1 |  | 1 | 118 | 12 | [prose-rule](controls-prose-rule.md) |
| **Total** | 121 | 110 | 38 | 83 | 1 | 8 | 12 | 373 | 125 | |

## Split cells, counted by arm

A split cell counts once under each class it names.

| Control | Mechanism kind | Arms | Cell as the register writes it |
|---|---|---|---|
| C-091 | hook-registration | code-enforce · code-off | code-enforce (floor) / code-off (ceiling) |
| C-092 | hook-registration | code-enforce · code-warn | code-enforce (-004) / code-warn |
| C-097 | hook-registration | code-enforce · code-off | code-enforce (floor) / code-off (ceiling) |
| C-101 | hook-registration | code-enforce · code-off | code-enforce (floor) / code-off (ceiling) |
| C-105 | hook-registration | code-enforce · code-off | code-enforce (floor) / code-off (ceiling) |
| C-106 | hook-registration | code-enforce · code-warn | code-enforce (-004) / code-warn |
| C-124 | deploy-check | code-enforce · code-warn | code-enforce (row layer) / code-warn (field layer) |
| C-190 | deploy-check | code-enforce · code-warn | code-enforce (parity arms) / code-warn (schema arm) |
| C-191 | deploy-check | code-enforce · code-warn | code-enforce (deadline arm) / code-warn (evidence arm) |
| C-194 | deploy-check | code-enforce · code-warn | code-enforce (deadline arm) / code-warn (evidence arm) |
| C-199 | deploy-check | code-enforce · code-warn | code-enforce (map-closure arm) / code-warn (byte-parity arm) |
| C-325 | prose-rule | code-enforce · prose-only | code-enforce (leak half) / prose-only (presence half) |

## Citations

125 of 373 controls are cited by at least one page, read from the Steps rows of activity pages and the Controls tables of the pages above them. The pages and steps citing each control are on [controls-cited](controls-cited.md). Cited IDs with no row in the register: none.

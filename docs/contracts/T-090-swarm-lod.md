# T-090 — Swarm LOD and elite visibility at strategic zoom

**Date:** 2026-09-09. **Status:** Proposed; not delegated. **Workstream:** E. **Owner:** Terra. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. The task is not authorized until D-135 is resolved.

## Dependencies

Pure new helper can be prepared after T-081 while D owns views; final integration after T-087 and F's T-092 assets/size metadata. No E view edits during D.

## Editable scope

new src/presentation/readability/swarm_lod.gd and its tests; release_view.gd only during E integration lease; per-task LOD data. F owns enemy textures and shapes.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

At strategic zoom draw standard machines as a readable directional mass using bounded batching/MultiMesh where appropriate; at tactical/close zoom preserve individual machine animation and shape. Derive density/bearing only from living visible targets, excluding burrowing/offscreen phases according to existing rules. Keep elites/Assembler individually drawn with D-131 physical display-pixel floors, class silhouette and depth layering; standards cannot fully bury them. Use hysteresis at LOD boundaries and preserve stable bearing under pan/zoom. Do not inflate actor spacing, change paths, hide a dangerous actor merely to improve a screenshot, or raise the 128-actor production cap.

## Done condition

128-machine shipping and separately 800/1,000-machine live stress captures show the dominant threat bearing within two seconds in at least 9/10 shuffled trials. The historical 1,031-sprite diagnostic is reproduced separately and improved using the live LOD/elite projection; retain original composition and annotate changed presentation floors. Five elites and boss remain locatable in mixed crowds at 1080/1440 across three palettes and grayscale; floor is measured in physical pixels after UI/frame scale. LOD threshold crossings do not flicker or change state. 42+ suites and production performance pass; stress timing is reported separately and cannot be described as 128-cap shipping performance.

## Evidence

Shipping/stress/historical crowd before/after, physical-size measurements, zoom/pan threshold clips, density projection tests and timed trials. Save under `docs/reviews/presentation-v3/T-090/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

LOD API, batch capacity/lifetime policy, physical-size conversion, class metadata and provisional thresholds/hysteresis.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

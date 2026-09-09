# T-082 — Distinct weapon, hit and death performance

**Date:** 2026-09-09. **Status:** Proposed; not delegated. **Workstream:** B. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. The task is not authorized until D-135 is resolved.

## Dependencies

T-081 and early T-083 adapter accepted; T-087 layout and E's shared-view integration frozen; C/F assets admitted or explicit nonfinal adapter stubs used only in isolated development.

## Editable scope

new src/presentation/effects/ combat helpers and assets/vfx/; release_view.gd/live_view.gd under the exclusive B integration lease; task-specific tests. Audio changes stay in C; request its event map instead.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Use a bounded presentation-event layer fed by accepted simulation hits/deaths and weapon kind. Flak: clustered ballistic flash/short tracers and metallic sparks. Mass Driver: heavy launch kick and dense single kinetic streak/impact. EMP: coil pulse and expanding electrical ring. Lance: brief charge/emission and coherent beam afterglow. Point Defense: tiny rapid pinpoint flashes, deliberately distinct from Flak. These timings visualize events and never delay damage or add travel rules. Add short wedge-hit light response and pooled, varied machine breakup/death effects. Weapon sound IDs come from C. Limit simultaneous effects by priority and class rather than arbitrarily dropping critical warnings. No floating damage-number feature in this pass.

## Done condition

A five-weapon blind clip set is correctly identified in at least 9/10 shuffled trials after one reference demonstration; no sound is needed for visual identity. Every actual hit retains its correct origin/target and damage tick; two simultaneous weapons remain distinguishable. Missing/dead target references, full effect pool, pause/quit/retry, reduced motion and effects-off are safe. Deaths do not spawn persistent nodes or mutate simulation state. 42+ suites and matched performance remain green.

## Evidence

Same-fixture five-weapon before/after sequences, mixed-combat recording, effects-off/reduced-motion comparison and pool lifetime/stress measurements. Save under `docs/reviews/presentation-v3/T-082/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Event-to-effect table, visual priorities/pool caps, timing/size tokens, C audio event IDs and teardown contract.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

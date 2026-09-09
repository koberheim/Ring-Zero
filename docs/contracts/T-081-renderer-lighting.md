# T-081 — Renderer, lighting and cache performance proof

**Date:** 2026-09-09. **Status:** Proposed; not delegated. **Workstream:** A. **Owner:** Sol. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. The task is not authorized until D-135 is resolved.

## Dependencies

D-135; T-086's isolated toggle slice accepted. No D-layout lease active.

## Editable scope

project.godot; scenes/application.tscn if needed; src/presentation/release_view.gd; src/presentation/solar_body.gdshader; src/presentation/industrial_space.gdshader; new src/presentation/lighting/ helpers; assets/art/materials/; task-specific presentation/performance probes. application.gd only for the agreed viewport/environment setup hook, under the exclusive lease.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

First reproduce RC2 performance and capture the unlit baseline. Implement a small six-ring light/canvas proof in Compatibility, then a Mobile comparison with matching visible intent; Forward+ is only a measured alternative if Mobile has a specific demonstrated limitation. Select the least costly backend that passes the appearance and feature requirements, documenting the reason. Prefer retaining Compatibility if it passes; its glow capability is verified. Add a coherent core-centred light response across bands, spokes and mounted heads; central warmth must decline toward the colder frontier. Separate albedo, normals and emission on a representative mount/head, then cover the shipping hardware surface families. Use actual geometry-based normals or a documented authored approximation, not a claim that grayscale AI albedo recovers physical normals. Resolve the separate World2D cache: lights/materials must affect the cached fortress, dynamic light/emission must update without repainting all static geometry every frame, and final bloom must include world transients while excluding UI. Preserve the spherical star, three palettes and scene depth. Freeze a viewport/layer/material adapter for D and B.

## Done condition

Native six-ring before/after at fixed camera and all three palettes visibly shows a consistent core-to-frontier light gradient, form on one head at all twelve bearings, corona bleed and a bright weapon sample without bloomed text or clipped white hardware. Demonstrate cache coverage/invalidation under pan, zoom, Alt, damage, collapse, reduced motion and palette/HP changes. All 42+ suites and native cache checks pass. Every matched performance sample stays within the shared 10% envelope; otherwise STOP and report. Record the backend choice and exact project/SubViewport settings. No full art pass or downstream renderer integration before this gate passes.

## Evidence

RC2/native Compatibility/lighting Compatibility/Mobile comparator captures, sample logs and delta table; all-palette six-ring lighting frame set; cache/pan/Alt clips. Save under `docs/reviews/presentation-v3/T-081/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Frozen rendering backend, world/canvas ownership diagram, normal/emission conventions, UI-exclusion layers, light-update API and provisional radii/falloff/threshold values.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

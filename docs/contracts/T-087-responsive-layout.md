# T-087 — Responsive native composition and correct map framing

**Date:** 2026-09-09. **Status:** Proposed; not delegated. **Workstream:** D. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. The task is not authorized until D-135 is resolved.

## Dependencies

T-081 lighting/cache contract, T-083 early adapter and full T-086 tokens accepted. Exclusive D lease; A/B/E view writers stopped.

## Editable scope

src/presentation/application.gd; src/presentation/live_view.gd; src/presentation/release_view.gd; src/presentation/camera_navigation.gd; src/presentation/instrument_strip.gd; scenes/application.tscn/project.godot only for approved layout/stretch settings. Task-specific layout/input tests. Preserve A's renderer choice.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Replace the fixed outer 1440p placement with anchors/containers and native-resolution viewport composition using shared layout tokens. Retain the existing useful inner containers. Define a usable-map rectangle after the build dock, telemetry rail and radar space are reserved; initial/reset camera framing uses that rectangle, while user pan remains free. Keep the star circular and ground projection/picking consistent. Implement compact, normal and wide arrangements rather than merely stretching all pixel offsets; 21:9 uses additional map space. Preserve text scaling at 100/115/130%, with reflow/scroll as necessary. Refresh native world/cache buffers appropriately on resize without resetting the run, losing focus or breaking A's lighting. Convert input through the actual current frame/canvas transforms.

## Done condition

All screen matrix sizes in the shared contract have no clipped essential controls, overlapping labels or unreachable actions. Initial one-ring fortress is centered in usable map area at 1080/1440/ultrawide; user pan is never forcibly recentered by a frame update. Actual mouse/controller placement, WASD held movement, wheel zoom, radar focus, Alt labels and cancel work after repeated resizing and scale changes. Verify direct native buffers at 1080/1440; 4K layout is checked without asserting a 4K frame target. All 42+ suites, cache checks and required 1440p performance pass. Changes to viewport/cache dimensions cannot silently leave stale light or picking coordinates.

## Evidence

Matched screen matrix before/after, resize/picking video, viewport/buffer dimension log and performance/cache report. Save under `docs/reviews/presentation-v3/T-087/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Stable usable-map rectangle, layout breakpoints/tokens, world-to-screen/input conversion functions and live viewport resize contract.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

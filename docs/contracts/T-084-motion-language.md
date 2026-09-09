# T-084 — Camera impulse and purposeful interface motion

**Date:** 2026-09-09. **Status:** Proposed; not delegated. **Workstream:** B. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. The task is not authorized until D-135 is resolved.

## Dependencies

T-082, T-087 and T-088 static screen composition accepted; D hands shared files to B.

## Editable scope

src/presentation/effects/ motion helpers; application.gd/release_view.gd/live_view.gd under the B integration lease; focused settings/input tests. D owns static layout and theme tokens.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Replace the tiny repetitive camera orbit with bounded noise/trauma-style translation that decays with event energy. Give collapse the dominant impulse and ordinary hits a much smaller one. Keep map aiming stable and reset offsets after pause, disabled effects and teardown. Add restrained press/focus feedback, one coherent screen transition and a skippable result-count reveal that does not delay saved rewards or navigation. No continuous hover lift or decorative animation on every panel. Respect reduced motion immediately, including animations already in flight.

## Done condition

Native before/after sequences show materially different small-hit and ring-collapse impulses without losing the aiming location. Reduced motion disables camera displacement and spatial UI transitions; essential states remain immediate. Fast repeated open/close/cancel and controller focus preserve action and screen order, with no leaked tweens/nodes or input lock. Stored result values never depend on the count-up. 42+ suites and native performance pass.

## Evidence

Same-event small/large impulse clips, reduced-motion and rapid navigation clips, pointer-transform/focus regression results. Save under `docs/reviews/presentation-v3/T-084/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Motion helper API and provisional amplitude/frequency/decay/duration tokens, cancellation and teardown behavior.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

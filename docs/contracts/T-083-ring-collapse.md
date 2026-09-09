# T-083 — Ring collapse vertical slice and catastrophe gate

**Date:** 2026-09-09. **Status:** Approved under D-135; assignment follows dependency gates. **Workstream:** B. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. Kevin approved D-135 on 2026-09-09. This contract is authorized subject to its dependency gates and Astra's explicit file lease.

## Dependencies

T-081 accepted; starts before T-087's rewrite. Final audible acceptance also depends on T-085.

## Editable scope

new src/presentation/effects/ collapse/event adapter; assets/vfx/collapse/; release_view.gd and live_view.gd under B's exclusive early lease; focused capture/test fixtures. No gameplay/rule edits.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Distinguish a broken wedge from collapsed_rings using actual committed events. Snapshot the lost ring's presentation geometry before its removal; emit sheared seam fragments, tumbling structural pieces with apparent depth, an outward pressure flash and a decaying camera impulse. Persist the visible gap and dead lights after transient debris expires. Sequence a brief fracture cue, mass separation and settling dust, with an independently designed collapse sound from C. Freeze an adapter API before D rewrites views. Do not use Engine.time_scale, slow the simulation, delay input or change collapse timing. Reduced motion replaces camera/debris movement with a short restrained emphasis and persistent structural loss; effects-off still makes the missing ring clear.

## Done condition

Retain a native real-time video OR timestamped lossless frame sequence spanning at least 1 s before and 3 s after collapse, including simultaneous wedge losses, inner-ring collapse and final-core loss. A muted unlabeled clip lets Kevin/designated unfamiliar reviewer state that an entire ring was lost, locate it and distinguish it from one damaged wedge; failure blocks advancement. Check actual ring removal/occupants/rewards on the original simulation tick, one cosmetic collapse admission per event, bounded fragments and cleanup after pause/retry/quit. 42+ suites and performance pass. Early visual slice can be accepted separately, but T-083 is not Done until the final C sound and integrated sequence pass.

## Evidence

Matched RC2 and new collapse videos/frame sequences, reduced-motion and effects-off versions, event/tick logs, muted comprehension result and final audio version. Save under `docs/reviews/presentation-v3/T-083/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Stable event adapter and saved-geometry shape, draw-layer contract, collapse envelope/priority, trigger deduplication and reduced-motion behavior.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

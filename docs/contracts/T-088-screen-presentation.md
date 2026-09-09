# T-088 — Start, HUD, pause, settings, controls and outcome composition

**Date:** 2026-09-09. **Status:** Proposed; not delegated. **Workstream:** D. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. The task is not authorized until D-135 is resolved.

## Dependencies

T-087 accepted; E supplies truthful radar/status projections; B/C supply frozen effects/audio IDs for final integration.

## Editable scope

application.gd/live_view.gd/release_view.gd/instrument_strip.gd in exclusive D screen lease; new src/presentation/ui/ and bounded run-memory helper; task-specific screen tests. No persistent progression/schema changes without review.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Make the living fortress/star the main visual subject of start and outcome screens. Start: hero and operation choices share an intentional alignment, one primary Start action, and plainly interactive secondary navigation. HUD: restrained telemetry rail, compact build dock, grounded tutorial/selection strip and a useful threat instrument. Pause retains a recognizable dimmed fortress and presents Resume first, followed by options and abandonment. Settings show numeric values and explanations; controls group movement, construction and abilities around their actual remapped keycaps. Results show a captured peak-fortress view and a compact radius history, one saved reward total, then the breakdown. Record bounded read-only presentation history during the run; do not fabricate peaks from a final state or modify rewards. Practice/abandonment/defeat and no-data history have honest distinct states. Repair compact-number rounding boundaries such as 1000.0M. B adds restrained motion after static composition is accepted.

## Done condition

Opening affordance, selected build, run goal, current threat and pause state can be located without scattered orphan labels. Start/options/results fit the shared native screen matrix including 130% scale; all controls are reachable by keyboard/controller. Peak image and radius graph match the actual recorded run; absent history is explicitly unavailable. Reward total equals the existing durable summary once, and zero-kill QA scenes are labeled in evidence. Victory, defeat, practice, abandonment, save-error and retry states all pass. Astra reviews actual captures; Kevin's final screen acceptance remains part of T-093. 42+ suites and performance pass.

## Evidence

Full screen before/after gallery, short controller navigation recording, real-run result example with peak/history verification and error/empty states. Save under `docs/reviews/presentation-v3/T-088/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Final static screen composition, bounded run-memory API, final UI anchors for B motion and C audio, rewritten player-facing copy.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

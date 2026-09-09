# T-091 — Readable ring integrity and power instrument

**Date:** 2026-09-09. **Status:** Approved under D-135; assignment follows dependency gates. **Workstream:** E. **Owner:** Terra. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. Kevin approved D-135 on 2026-09-09. This contract is authorized subject to its dependency gates and Astra's explicit file lease.

## Dependencies

T-087 layout rectangle and T-089 state mapping; T-086 tokens. E owns radar implementation, D later composes around its frozen preferred size.

## Editable scope

src/presentation/ring_status_hud.gd; new src/presentation/readability/ status helper; focused radar tests. application/live host positioning only through agreed layout interface or exclusive lease.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Strengthen wedge fills and broken/critical/relay/brownout symbols while keeping each of the twelve shipping rings individually inspectable. Size the instrument responsively to preserve a useful band thickness, with exact ring/wedge identity on focus/hover and click-to-focus retained. Use shape/pattern plus color; persistent failure is visible without requiring flashing. Preserve full positional truth and hover/click hit regions after UI scale or window changes. Proposed treatment enlarges/reflows the instrument rather than introducing aggregation/scroll semantics beyond eight rings.

## Done condition

At twelve rings, every band is at least 6 physical pixels at the 1080/1440 primary layouts, or an explicitly reviewed reflow preserves equivalent individual access. A shuffled healthy/critical/broken/relay-down/brownout fixture yields correct failing ring and bearing within two seconds in 9/10 trials, including grayscale/reduced motion. Click/focus mapping remains exact for all twelve rings and wedge boundaries after resize. No status is sourced from stale cached presentation. 42+ suites and performance pass.

## Evidence

Same-state before/after radar at 1/6/12 rings and 1080/1440/ultrawide, state symbol key, mapping checks and timed trials. Save under `docs/reviews/presentation-v3/T-091/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Preferred/minimum instrument size, status projection API, focus signal and final provisional contrast/stroke/band tokens.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

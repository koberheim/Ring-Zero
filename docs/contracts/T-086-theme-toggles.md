# T-086 — CheckButton quick win and complete instrument theme

**Date:** 2026-09-09. **Status:** Approved under D-135; assignment follows dependency gates. **Workstream:** D. **Owner:** Luna. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. Kevin approved D-135 on 2026-09-09. This contract is authorized subject to its dependency gates and Astra's explicit file lease.

## Dependencies

**Preparation lease — Astra, 2026-09-09, base `c76a45c`:** D may perform read-only source/screen audit and write task-specific T-086/T-087 preparation evidence now. Apply the frontend-design skill to a compact approved-style token/layout plan, actual control inventory and planned native matrix. No source, assets or Godot writes/runs during B's early collapse lease. Full theme/layout implementation follows B's frozen reviewed adapter; the old early-slice lease below is historical, not concurrent runtime authority.

**Active lease — 2026-09-09:** Stream D / Luna may implement only the first CheckButton/OptionButton quick slice from source `1f9a710` plus the D-135 approval record. Editable: `src/presentation/industrial_theme.gd`, `assets/ui/controls/`, narrowly named T-086 capture/check fixtures, and `docs/reviews/presentation-v3/T-086/` plus its parent `.gdignore`. No application/live/release layout or renderer edits, no full-theme rewrite yet. Capture the current real start/settings states before editing. Exclusive Godot import/capture/test lease is granted for this slice; coordinate release to Astra for independent review. The later full-theme lease is not active.

D-135 for the isolated first slice; remainder after T-081 and T-083 visual adapter freeze. No overlapping A lease.

## Editable scope

src/presentation/industrial_theme.gd; new src/presentation/ui_tokens.gd; assets/ui/controls/; task-specific theme fixtures. Fallback-font replacement in release_view.gd/live_view.gd/application.gd only in the later D lease. Do not start layout in the first slice.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Continuation inventory preparation (Astra): current production construction uses Button, CheckButton, OptionButton (implicit PopupMenu), TabContainer (implicit TabBar), ScrollContainer (implicit scrollbars), ProgressBar and PanelContainer. Existing source scan found no direct Tree/ItemList construction; confirm scene usage before adding unused styling. Full theme must include implicit child controls, popup/focus/tooltip states and world font replacement, while retaining the accepted early SVG switches. Native 1080px text should be sized for its actual display, rather than left at 1440px defaults after D removes the old 0.75× scaling.

FIRST delivery: a legible two-position switch with explicit on/off geometry and text/state contrast, disabled versions and clear keyboard/controller focus; replace OptionButton arrow with a matching asset. Verify real challenge rows and settings at 1080/1440 rather than only a widget gallery. Then complete a shared instrument theme for every actually used control: Button, CheckButton/CheckBox, OptionButton/PopupMenu, TabBar/TabContainer, LineEdit, sliders, scrollbars, tooltips, panels and progress bars; style Tree/ItemList only if the screen inventory uses them. Use a consistent Barlow family for body, condensed headings and tabular numeric roles, including live world labels. Distinguish raised actions, recessed choices, instruments and explanatory text with material hierarchy instead of the same shadowed box everywhere. Adopt the Phase 14 palette/type/spacing tokens; keep visible focus and selected states without color alone.

## Done condition

Early toggle slice is separately reviewable with on/off/disabled/hover/focus before/after and actual settings persistence/input checks; no tiny default engine switch or arrow remains. Full completion requires a screen/widget state inventory with every used type accounted for, no unintended default icons/font fallbacks, readable disabled text and focus at 1080/1440 and 100/130% scale. 42+ suites pass; capture T-086 early slice before A begins. T-086 stays In progress until full theme integration passes.

## Evidence

Start/settings before/after plus native widget contact sheet covering all states, type/spacing token sheet and focus traversal clips. Save under `docs/reviews/presentation-v3/T-086/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Theme and size/color/type tokens with semantic roles; control-state resource map; shared font access for drawn world text.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.

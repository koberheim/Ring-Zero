# T-023 - Measure and reduce repeated live simulation work

Owner Terra. Start only when assigned after the T-022 rendered bottleneck report. Own src/gameplay/live_simulation.gd, src/gameplay/wall_navigation.gd, tests/gameplay/test_live_simulation.gd, tests/gameplay/test_wall_navigation.gd, and docs/reviews/T-023.md. No core, weapon, profile, or presentation changes; no delegation. Read owned files and this brief. Ask Astra for any missing consumer contract instead of exploring other lanes.

T-021 gameplay is accepted: two shared route fields prefer exposed surfaces, falling back to wall HP only when no exposed target is reachable; quarter normal DPS, immediate later-ID rerouting after a break, staged rollback, polar waypoint continuity, fixed60Hz and1000 trial capacity. Public APIs and event meanings must remain identical.

Independent headless baseline: sealed1000 median14.654ms/p9015.312; angular1000 median17.279ms/p9017.476, three warmups/ten samples, initial route build only, no measured scheduled volleys. The duplicate preflight snapshot has already been removed. Do not claim that correction again.

First measure snapshot/preflight, route/movement, weapon call, and persistence costs separately in an explicitly instrumented fixture. Do not change movement, combat cadence, enemy count, spawn rate, clock catch-up, validation, or rollback semantics. Coordinate benchmark timing through Astra so no other agent is simultaneously measuring.

Candidate changes within this task: cache immutable route results per cell in each WallNavigation snapshot; eliminate redundant success-path container creation; remove repeated sorted-ID cleanup by checking existing pool membership. Implement one measured correction at a time. Internal position sharing requires a verified downstream immutability contract and Astra review first; public targets_snapshot results must always remain independent. If PolarMotion dominates, return evidence for a separate Sol task rather than changing core code.

Preserve immediate invalidation after purchases, wall destruction, wedge breaks and collapse; external fixture changes remain detected at tick start. Caches and waypoints must roll back on failed ticks, including failures after rebuild and tentative admissions. Returned route dictionaries must not allow callers to corrupt the cache. Do not share mutable result containers between public calls.

Verification: retain all T-021 focused checks and consumer behavior. Add only tests for actual regression risks introduced by the correction, especially caller mutation isolation and same-tick cache invalidation. Compare the unchanged1000 sealed/angular fixtures before/after. Include a longer consecutive normal-cadence sample covering scheduled volleys, with full state/event correctness, counts of moved/attacking machines, hits and rebuilds. Report fixture geometry, warmup/sample counts, median/p90 and limitations. Keep pinned Godot4.7.2, workspace caches, tracked hidden processes and bounded waits. No final crowd-cap claim.

Done when the measured correction passes the relevant checks, source is stable, and Astra reviews the report before Luna reruns rendered measurements. A small verified gain is preferable to an unmeasured redesign; if no safe gain exists, report evidence and stop for Astra's next bounded handoff.

## Reviewed internal ownership clarification

Astra inspected WeaponRules.step: it deep-copies target dictionaries and explicitly clones each PolarPosition before changing copied health. PolarMotion reads inputs and returns a separate position. Live movement assigns a replacement position; it does not mutate the old object's fields. Therefore a PRIVATE staging builder may initially reference existing pool positions as read-only, replacing them when movement occurs. Public targets_snapshot still clones every position. Test original pool positions across successful movement and failed pre/post-movement or admission ticks, plus external snapshot isolation. Retain only if measurement improves costs. No weapon implementation change is authorized here.

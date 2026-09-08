# T-022 wall prototype review point

Astra reviewed source, four actual viewport captures, input tests and rendered measurements. Independent final Godot4.7.2 reruns passed84 wall,66 live and49 build checks; the restored PolarMotion suite also passed. Logs: `.godot/final-wall-astra-*.log`.

Approved controls and grayscale feedback are ready for Kevin's D-073 stage review. Walls cost5, use no slot, draw on the outer curved edge, show selected health, disappear on breach/collapse, and leave surviving outer structures intact. Open routes cause detours; sealed routes allow25% wall damage. Loss, pause and invalid-placement behavior remain verified.

This is not full performance acceptance. Final1000 rendered sealed fixture:18.986ms median/30.840ms p90. Angular:96.529/148.919ms, with strict continuity failure (57of120 probe frames still angular). Both retain1000 instances. Angular is mixed movement/contact diagnostic evidence, not a successful funnel benchmark. T-023 reduced repeated work; T-024 found no reliable gain and restored its source. See T-022.md for samples, events, overrides and limitations.

T-022 remains in review. D-073 can accept stage controls/feedback while performance remains open. No final capacity, balance, art or frame-rate acceptance is claimed. Further engineering preserves trial count, speed and cadence.

Kevin subsequently accepted D-073 Option A. Stage controls/feedback acceptance is complete; the documented performance failure remains open.

## Latest rerun after T-025

The unchanged HP1e8/DPS1 rendered fixtures now both pass their functional/load assertions. Sealed median16.650ms/p9016.863ms,120ticks in120frames,1000active and440hits. Angular median49.120ms/p9049.666ms,336ticks in120frames,all1000changed angles and all120probe frames remained angular; no measured hits, HP damage or route rebuilds. Source/fixtures were unchanged; only the accepted T-025 combat-copy correction differs. Both used three-second warmup and120measured frames.

The earlier failed angular results remain historical diagnostics. Continuous-angular coverage is now established for this fixture, but its roughly20FPS is still below60Hz. T-022 performance remains in review; D-073 stage presentation approval and D-007 final performance acceptance remain separate.

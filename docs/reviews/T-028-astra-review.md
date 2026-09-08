# T-028 visible Tunneler review

2026-09-07. Functional implementation passes Astra review; Kevin accepted the stage as D-080 Option A on 2026-09-07. T-028 remains in review because rendered crowd performance is unresolved.

Astra independently ran 47 Tunneler, 66 live-view and 84 wall-view checks (197 total, zero failures, pinned Godot 4.7.2, tracked hidden processes). Logs: `.godot/t-028-astra-tunneler_view.log`, `.godot/t-028-astra-live_view.log`, `.godot/t-028-astra-wall_view.log`. Source review confirms main-scene enablement, separate batched normal circles and surfaced triangles, destination-only underground warning, simulation-derived countdown and unchanged gameplay rules.

Five actual 1280x900 captures cover the warning, zoom, surfaced overlap, unobscured surfaced triangle and inner collapse. Astra inspected the warning at both zoom levels, original overlap, clear triangle and collapse. Countdown is readable beside the starter Flak. The approved three-pixel triangle is difficult to distinguish when it coincides with a filled building marker; the overlap capture is retained rather than hidden. The collapse clears inner buildings while the outer relay survives.

Captures use declared fixture funds, quiet normal spawning, zero Flak damage, durable wedge HP and accelerated first arrival at 0.05 seconds. The collapse fixture pre-breaks six inner wedges and weakens the seventh; real scheduled Tunneler damage causes collapse. The separate clear-triangle capture purchases three rings. Production timing remains first arrival at 60 seconds, then every 30 seconds, with a two-second burrow.

Luna's unchanged 1,000-normal-machine sealed fixture measured 16.828 ms median / 19.300 ms p90. Angular attempts measured 101.119 / 116.579 ms, then 103.576 / 117.637 ms in one fresh repeat. They retained all 1,000 machines but passed continuous angular motion for only 66/120 and 65/120 frames because accumulated simulation ticks reached contact. These are failed continuous-motion checks and mixed-motion diagnostics, not valid comparisons against the prior 49.120 ms continuous-angular result. No threshold, density, speed or cadence was relaxed. Cause and final swarm capacity remain unresolved; do not claim 60 Hz acceptance.

D-080 asks only whether these visible Tunneler placeholders and behavior are sufficient for this stage. Final art, balance and swarm performance remain open.

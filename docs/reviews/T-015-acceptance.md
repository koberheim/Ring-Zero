# T-015 acceptance

Astra accepted T-015 on 2026-09-06 after reading the source, independent reference tests, and report, then rerunning the focused suite on pinned Godot 4.7.2. Result: PASS, exit 0. Evidence: .godot/t-015-astra-review.log. The known certificate-store diagnostic did not affect the offline tests.

Review verified explicit legal neighbor connections, copied graph inputs, deterministic distance/goal/next-cell ordering, binary heap computation, unreachable sentinels, rebuild isolation, and no gameplay defaults. The independent all-pairs reference verifies weighted distances and goals; path-chain checks verify supplied edges, termination, and total costs. Extreme overflow and rounded-away additions return errors with no partial field.

Astra's unchanged 100-ring benchmark (1,201 cells, 2,400 edges, three warmups and ten samples) measured rebuild median 20.000 ms, p90 20.471 ms; all-cell three-query sweep median 0.799 ms, p90 0.819 ms. These are headless utility timings. Rebuilding at this size exceeds one 60 Hz interval and must remain a measured integration concern. No asynchronous/stale-route scheduling or reduced crowd cap is authorized by acceptance.

This completes the engine utility, not a live enemy loop. Gameplay must supply destinations, barriers, and traversal costs through a subsequent contract; presentation must then consume the integrated simulation.

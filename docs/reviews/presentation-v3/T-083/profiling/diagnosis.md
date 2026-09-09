# Dense failure diagnosis — paired static cache refresh

The reproduced100–120ms measured stalls follow **whole-fortress paired albedo/material cache rebuilding after wedge loss**. Disabling collapse drawing or all geometry admission leaves those stalls. Holding both static caches removes them while the actual simulation and collapse effects continue. Cache-hold is deliberately visually stale and is **not a fix or passing acceptance result**.

No production source was changed. All probes ran from isolated `67a49cb` with narrow timing instrumentation under a root-coordinated D/E/Blender/all-work freeze. Godot4.7.2/Mobile/RTX4080/driver610.88;2560×1440, zoom.41, same reconstructed dense04 profile and128 initial actors. Every launch saved source files and hashes before Godot started. Import passed; all native trials exited0 with their actual-event/fixture assertions intact. The known certificate and missing-audio warnings remain.

| Case / repetition | Median ms | p95 ms | Max ms | Paired rebuilds during180 frames |
|---|---:|---:|---:|---:|
| Normal01 /0 |16.652|20.190|111.620|3|
| Normal01 /1 |16.540|18.964|120.014|3|
| Draw-off /0 |16.671|19.321|112.291|3|
| Draw-off /1 |16.594|19.863|112.301|3|
| Admission-off /0 |16.683|19.809|113.767|3|
| Admission-off /1 |16.638|19.543|116.810|3|
| Cache-hold /0 |16.676|17.288|19.505|0|
| Cache-hold /1 |16.635|18.898|21.006|0|
| Normal02 /0, canonical numeric target hash |16.654|20.469|112.218|3|
| Normal02 /1, canonical numeric target hash |16.611|19.333|115.065|3|

The original111.127ms failure remains retained. The new comparisons reproduce it repeatedly, including the second trial in the same process, so a one-time-only first-use explanation is insufficient. Some rendering/driver cost may still be involved in each rebuild; this instrumentation did not measure GPU duration or driver internals and cannot allocate the full112ms between them.

At normal02's112.218ms worst frame (tick189), the albedo rebuild CPU cost10.215ms and material rebuild11.592ms. Collapse immediate draw submission cost0.693ms, event hook0.045ms, state copy0.087ms and repair loop0.029ms; simulation callback5.241ms and sync2.420ms. At draw-off's112.291ms worst frame, collapse drawing is exactly0, but the two rebuilds still cost10.459/10.708ms CPU. Admission-off likewise stalls with zero retained pieces. Cache-hold retains live effects and simulation, with no paired rebuilds. These are CPU timings and frame wall times, not interchangeable GPU timing measurements.

## Important limits

The original fixture warms up for60 **rendered frames**, not60 simulation ticks. Here that reaches simulation tick98–106 because rendering stalls make time advance. Consequently ring12's actual collapse at tick67 occurs during warmup; the measured maxima are later wedge breaks around ticks128/189/250 as the same attacker advances inward. This diagnoses the reproduced measured failure, but does **not** measure the initial120-hardware snapshot admission or95-live-RepairNode warmup cost. Those remain required in repair verification. Repair nodes have been removed with their collapsed ring by the measured interval, so their low measured CPU cost is not a benchmark of95 active nodes.

Normal01 and draw-off used `JSON.stringify` on snapshot records containing PolarPosition objects. Their target hashes encode object identities and are unsuitable for payload equality; they are retained without rewriting. The diagnostic was repaired to encode numeric ring/wedge/radial/angular values. Normal02, admission-off and cache-hold have exactly matching state hash `46307175f0284a179e4091edf3276f56227fe8ffe32d6cd6e2d85387c548bf24` and numeric target hash `eaf8c93a13f549cdf55b628b052db1a1e0b22224783201a35e64e6dcb927014c` in both repetitions. Same payload generation and tick67 event are retained across cases. Source snapshots show the exact diagnostic-only hash correction.

Repetition simulation/wall ratios sometimes exceed1 by a few percent: measurements begin/end on rendered-frame boundaries while fixed ticks catch up across long preceding frames. This is not evidence of an Engine.time_scale change; no time-scale or gameplay code change was made. The original ratios and full timelines remain available. Future verification should log clock/frame phase boundaries rather than smooth them away.

These are diagnostic comparisons with instrumentation overhead. Cache-hold repetition1 still exceeds the canonical p95/max envelope (18.898/21.006ms), and its stale world is never acceptable. Neither the chart nor this diagnosis waives any original performance requirement.

## Repair proposal and ownership

Assign the cache architecture repair to **Sol/Stream A**, coordinated with current D ownership of release_view and viewport transforms. B can supply the retained fixtures and event timing. The immediate problem is rebuilding both complete fortress rasters when one wedge's HP bucket/occupancy changes. Separate static geometry into bounded dirty ring/sector/tile regions so unchanged fortress commands and materials remain cached. Update albedo and normal/emission attributes together; preserve A's World3D/glow ownership and D's viewport/picking transforms.

Do not fix this by suppressing invalidation, delaying structural loss, lowering actor counts, dropping authored hardware or extending warmup to hide the spike. No cache-hold behavior should land. A repair should keep actual wedge/ring removal visible on its committed tick, including dead lamps/relay state and surviving occupants. Choose the partition after profiling its redraw cost and memory; this report does not authorize an unbounded set of full-screen viewports.

Verification should retain unchanged canonical samples, and rerun dense04 plus bounded05 with exact initial payload hashes. Record frame-by-frame costs from before tick67 through the later128/189/250 losses (including warmup as diagnostic data). Compare with collapse drawing on/off only to catch regressions, retain all failed samples and re-run the native lighting/cache/pan/picking and T083 behavior suites. Add actual production damage/collapse sessions and D's native resolution matrix; the durable canonical fixture alone does not exercise these invalidations. GPU/driver tracing may refine the residual cost if incremental redraw still stalls, but the present evidence is sufficient to prioritize whole-cache invalidation repair.

Artifacts: individual `trial-*.json` timelines, per-launch `source/`, `source-manifest.json`, command/stdout/stderr logs, generated `summary.json` and `profiling-manifest.json`. The instrumentation marker records original installation hashes; the per-launch snapshots are authoritative after the numeric-hash diagnostic repair. The isolated project remains available at `.godot/release-qa/t083-profile-base` for the next assigned owner.

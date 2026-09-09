# Phase 14 — shared delegation and evidence contract

**Date:** 2026-09-09. **Status:** Approved by Kevin under D-135 on 2026-09-09; execute in dependency order.
**Authority:** Kevin's critique response; D-129–D-134; fixed spec; CLAUDE.md. All task contracts below inherit this file.

## Scope and roles

Astra plans, assigns one agent per workstream, reviews every delivery and integrates accepted changes/logs. Astra does not write feature code or resolve feature conflicts by implementing a fix; the owner repairs them. Sol owns engine/performance, Terra owns faithful state/readability projections, Luna owns presentation/audio/art. Separate Luna agents may own separate streams. At most three child agents run alongside Astra; a stream can yield and later resume with the same contract. No nested implementation delegation or extra uncontracted lanes.

D-129 preserves bounded 15-minute Containment. Do not change deterministic simulation timing, damage, targeting, progression, machine capacity, wall rules, north-up orientation or the fixed spec. D-131 relaxes only elite/Assembler art constraints. D-134 permits provisional numerical presentation tuning, recorded with units/rationale in versioned tokens and the task delivery. D-130 requires free online AI audio source generation; no paid purchase/subscription.

The bounded visual/sonic choices described in these contracts were approved in D-135's single plan review. A new creative/rule departure beyond them goes to Kevin. Optional damage numbers, gameplay slow motion, a new voiceover/narrative, a different world palette, a new minimap aggregation mechanic and a higher shipping crowd cap are excluded from this plan.

## Collision and integration protocol

Astra grants a named file lease in the task brief, starting from an identified commit. Only listed files/directories and task-specific tests/evidence are editable. Broad `src/presentation/` ownership is never implied. Never revert another lane's edits or stage the whole workspace.

A, B, D and E all need `application.gd`, `live_view.gd` or `release_view.gd` at different times. These files have **one writer at a time**. A and D never run overlapping implementation leases. D's T-087 can rewrite the three views only after A's rendering interface and B's early collapse interface are frozen. C may work in its audio helper/assets; F in its enemy assets/briefs; E may prepare a new LOD helper while D works, with integration deferred.

Freeze reusable interfaces by a short reviewed handoff note: world/view transforms and lighting layers from A; presentation event adapter from B; usable-map rectangle and UI tokens from D; read-only bearing/density/status data from E; enemy asset pivots/atlas/emission/size metadata from F; event IDs/buses from C. Owners specify exact data shapes in their delivery before consumers modify integration code. Adapters consume existing state and events; they never manufacture gameplay events.

One Godot import/capture/test/export process at a time against this checkout. Performance runs hold an exclusive source/assets/runtime freeze, with no Blender rendering, competing Godot process or local GPU job. If a lane needs more files, Astra revises its written contract/lease before the edit. Accepted code lands in atomic task commits; no RC tag/version promotion until T-093.

## Baseline and evidence

Reference source: `ebeaf72` (RC2). Reference evidence: `docs/reviews/presentation-v2/`; original art evidence: `docs/reviews/artifacts/T-079-*.png`. Never overwrite these. Preserve Kevin's critique unchanged.

Each task writes `docs/reviews/presentation-v3/T-0NN/` with a report, before/after images or clips, fixture metadata, test results, exact commands, engine/backend/GPU/driver, source commit or tree hash, resolution, UI scale, camera/zoom, palette, seed, simulation tick and active actor count. Include .gdignore at the new evidence root. Final manifests hash every artifact. Label diagnostic states and rendered mockups; only native game output passes in-game acceptance.

Use the existing graphical Godot capture pattern: instantiate `scenes/application.tscn`, isolated temporary profile, await `RenderingServer.frame_post_draw`, save the actual root viewport image. Start from `tests/presentation/capture_release.gd`; preserve fixture state and time for before/after comparisons. Add narrow deterministic captures rather than silently retuning the fixture to look better. Capture images at native resolution; do not upscale a small render or use image generation as gameplay evidence.

Core screen matrix: start, settings, controls, pause, opening, six-ring combat, twelve-ring combat, tactical overlay, victory and defeat at **1920×1080**, **2560×1440**, **3440×1440**. T-087 also covers 1280×720 compatibility, 1600×1000 and 3840×2160 layout/input. Include 100%/130% text scale, all three star palettes where world art changes, mouse, keyboard and controller focus. Reflow is allowed; tiny text and inaccessible controls are not.

For motion, capture real-time native video or a lossless frame sequence with frame timestamps, before/during/after event state and reproducible playback instructions. T-083 requires matched before/after motion evidence in either format; a still cannot pass. Audio work also needs native loopback recordings and a cue audition reel; screenshots alone cannot prove sound.

## Correctness and performance gates

The retained baseline is **42/42 suites**, superseding the critique's older 39. Run `scripts/run_tests.ps1` against every integrated workstream delivery, including all newly added suites. Do not delete assertions or re-record behavior baselines to hide a regression. Any regression returns to its owner. Preserve pause, cancel, remap migration, UI scale, transformed picking, reduced motion, effects-off, persistence/reward idempotency and clean teardown. Tests must verify behavior rather than mirror implementation.

T-081 compares `tests/performance/measure_release.gd` with `presentation-v2/native-performance.txt`: Godot 4.7.2, RTX 4080/NVIDIA 610.88 where available, 2560×1440, twelve rings, 128 machines, effects enabled, zoom 0.41, 60 warmup frames and 180 measured frames. Retain vsync/pacing configuration. Baseline median **16.668 ms**, p95 **16.760 ms**, max **18.489 ms**, simulation/wall ratio **0.999980667**.

Interpret Kevin's 10% frame-budget limit explicitly: median <= **18.3348 ms**, p95 <= **18.4360 ms**, max <= **20.3379 ms**, with simulation/wall ratio >= **0.99**. Log callback/draw/sync/quote times too; they are diagnostics rather than interchangeable GPU-frame measurements. Report every sample. A breach pauses progression immediately and goes to Kevin; never hide a failing sample inside an average. Diagnose noise with additional samples only after reporting it. On different hardware/driver, retain the archived comparison and establish an RC2 same-machine control; mark the historical measurement non-comparable rather than claim a pass.

Use three paired runs for repeatability. The original 60 Hz capture can mask headroom; add an uncapped diagnostic on both backends, but it does not replace the required matched test. Recheck pan, held Alt and pan+Alt using `measure_world_layers.gd` and the retained pan/tactical report. Re-run the native suite after each integrated visual stream and at final freeze. New effects, overdraw, native ultrawide buffers, LOD and audio decoding can also cost frame time; the renderer switch is not literally the only risk.

Production acceptance remains twelve rings/128 live actors. Separately run 800 and 1,000 live-actor stress diagnostics and the unchanged 1,031-sprite art fixture. Do not lower density or inflate spacing to make evidence pass. Stress readability is required; no unsupported 1,000-machine shipping performance promise or cap increase is implied.

## Human and release gates

Astra independently inspects artifacts and reproduces the stated exit check. Machine assertions cannot certify beauty, sound fatigue or an uninitiated player's comprehension. For the specified blind/readability/listening checks, Kevin or a reviewer he designates records answers against unlabeled clips/images. Do not contact other people automatically. A self-review is explicitly identified and does not count as a blind human result.

A workstream is Done only with all its checks accepted. An unchecked condition is pending, a failed condition is failed. Report failed gates with evidence, impact and a concrete owner repair proposal; do not continue downstream through them. Passing tests alone does not close T-079. D-132 blocks candidate promotion until T-093 verifies every mapped art and presentation gate. No silent waiver, renamed check or new baseline substitutes for acceptance.

Notify Kevin when the plan is ready, a workstream lands, a gate fails or a decision is needed. Do not send agent-start announcements. End each delivery with changed paths, commit, tests/evidence, provisional values, outstanding risks and an explicit pass/fail matrix.

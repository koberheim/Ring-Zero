# T-081 — Mobile lighting/cache delivery for review

Sol, 2026-09-09. **Implementation and selected-backend native checks pass; Astra review pending.** Human aesthetic judgment and final integrated presentation gates remain pending. No release promotion is claimed.

The fortress now has a shared core-centered light response on independently cached albedo, authored geometric proxy normals and emission. Native six-ring captures show a warm inner structure and a colder frontier; all twelve head bearings have verified inward-facing normals. Palette/core-energy changes update shader uniforms without repainting the fortress. World glow includes bright transients and excludes interface CanvasLayers. The star retains its existing spherical surface shader and all three palettes.

**Mobile is selected in both `project.godot` renderer entries.** Compatibility's three final matched maximum intervals breached the historical limit, while Mobile's three passed. The original unchanged RC2 also intermittently breached that limit. These failures remain visible; they were neither averaged away nor used to create a replacement baseline. One first-trio sample per backend has possible brief read-only CPU-check overlap; two later pairs were fully frozen. Astra can supply a third unambiguously frozen selected-backend sample during independent review.

## Checks and result limits

| Check | Result |
|---|---|
| Clean import and all discovered Windows native-runner correctness suites | **44/44 PASS**, including T-085 audio84 and T-081 lighting21 checks |
| Selected default Mobile native lighting/capture proof | **41/41 PASS**, PID34388 |
| Existing native camera/cache/picking proof on selected Mobile | **10/10 PASS**, PID4276 |
| Selected native pan/Alt/pan+Alt frame sequence | **24/24 saved**, PID34088, timestamps retained |
| Compatibility proof | **41/41 PASS** after normal/glow repairs; rejected by matched max-frame results |
| Twelve-bearing normal orientation | PASS native pixel readback on both backends; inward direction dots>0.75 |
| Palette/HP changes and strategic pan avoid raster repaint | PASS; paired material/albedo invalidation agrees |
| Zoom, damage, relay death, collapse, reduced motion, effects-off | PASS logical/cache integration assertions; actual render/camera checks retained separately |
| Native world glow / UI exclusion calibration | PASS; identical white emitters on opaque black, positive world halo / UI annulus difference exactly0 |
| Selected matched Mobile samples02/03/04 | All within numerical envelope;02 has possible read-only CPU-check overlap |
| Compatibility matched samples02/03/04 | **FAIL max**, all retained |
| Moving T-092 normal/emission atlas integration | Helper/contract delivered to E; actual live atlas integration remains E's work |
| Human appearance / broader T-079 presentation closure | PENDING; no automated beauty/readability claim |

Full suite log root: `.godot/test-logs/run-20260909-040346-056-15684/`; copied summary `test-summary.json`. The suite runner is a native Windows executable with headless correctness processes; the separate capture/cache/motion commands above actually render using Vulkan Mobile. Every command has PID, elapsed UTC boundaries, backend and return status in `*.command.json`. Certificate-store read diagnostics remain the previously recorded sandbox limitation. T-085 prints an explicit unadmitted-development-audio warning; audio source admission is not claimed by this delivery.

## Measurements and backend choice

See `performance-table.md` and `performance-samples.json` for **every** canonical trial, including the original failure, invalid audio-parse trials and overlap caveat. Original fixture and pacing are unchanged: Godot4.7.2, RTX4080, NVIDIA610.88, 2560x1440,12 rings,128 actors,effects on,zoom0.41,60 warmup/180 measured frames.

The selected Mobile runs measured medians16.705/16.683/16.688 ms, p9517.442/17.185/17.437 ms, maxima19.786/19.395/19.363 ms, with simulation/wall ratios>=0.997996. Approved ceilings are18.3348/18.4360/20.3379 ms and ratio>=0.99. Compatibility maxima33.531/21.102/22.374 failed despite medians near16.665 and p95 near16.75. Unchanged RC2 maxima included21.760 and33.357 failures as well as16.934 and19.478 passes. The evidence does not identify the source of the intermittent GL maximum intervals; it does establish that Compatibility cannot be accepted under the retained every-sample rule.

Uncapped diagnostic uses a separate probe with seed81081, palette1, vsync explicitly disabled, unlimited engine max_fps, and every raw frame interval retained. Mobile median12.922/p9514.488 ms; Compatibility14.471/15.256 ms. These are callback-to-callback wall intervals with fixed-step/sync pacing still present (the raw series is bimodal), **not isolated GPU times** and not substitute acceptance tests. Earlier harness wording called their arithmetic a matched pass; that label is corrected in the final runner and this report.

Native movement ablation on selected Mobile: pan median16.680/p9517.598, held Alt16.675/18.233, pan+Alt16.679/17.781 ms; zero fortress redraws in every measured state. Compatibility also retained its cache and had lower paced p95. Separate Mobile no-sun p9519.245 and no-HUD18.490 are retained diagnostic anomalies; they are not hidden or passed as canonical fixtures. This does not increase the shipping crowd cap.

First-trio freeze caveat: F later reported a read-only decoded-image hash check taking0.084 s after its initial freeze acknowledgement; exact wall time is unknown. RC2-03, Compatibility-02 and Mobile-02 may overlap. F then stopped all work, and the later pairs were fully frozen. No failure or pass was deleted because of this uncertainty.

## Native visual proof and repairs

`rc2-unlit-gl_compatibility-palette-{0,1,2}.png` are actual untouched-RC2 before captures, using the added deterministic capture probe only. The fixture starts at simulation time0 with120 durable actors,six rings,seed81081,phase0,camera origin,zoom0.85,ui_scale1; it mounts the same Flak representative at all twelve ring3 bearings. Metadata is retained per backend. They are labeled diagnostic fixture captures, not natural gameplay claims.

Final selected output is under `selected-mobile/`: all three palette frames, low-core response, pan,Alt,detail, independent albedo/normal-emission raster readback, weapon glow on/off and matched world/UI emitter calibration. The calibration sums positive world halo outside the white silhouette while the identical UI black annulus stays byte-identical. Actual weapon/star ablations remain available for visual review, not just node/property assertions. The slight subthreshold bloom is intentional and recorded below.

Native proof exposed and repaired real defects during development:

1. Implicit normal-green inversion initially pointed the inward bevel outward at all twelve bearings. Explicit channel decoding plus a UV-derivative tangent basis now passes native direction checks.
2. The absent specular texture defaults white; treating it as emission lit every primitive. Flat untextured primitives are now rejected as authored lamps, with existing HP-dependent band lights kept as explicit geometry. Dead relay tint suppresses authored lamps, and fortress emission follows core energy.
3. An unisolated stage environment could process the composed root. The stage now owns its World3D and uses an opaque background.
4. Early LDR glow threshold/intensity values produced no measurable halo in the native emitter calibration. An isolated native test proved capability; calibrated settings now produce positive world halo while UI remains unchanged. Earlier failed41-check logs are retained.
5. Mobile's LDR transparent-cache output had alpha1/3 for opaque texels on this engine/driver. HDR2D caches restore correct coverage/normals, and explicit linear-to-sRGB albedo conversion preserves the intended LDR appearance.

## Handoff, values and provenance

Read `adapter.md` for exact layer ownership, methods, material channels, moving-hardware helper and resize/invalidation obligations. B may add world transients on canvas<=0. D must keep the paired cache projections synchronized and interface layers>0. E has a one-material-per-canvas dynamic normal/emission shader and a declared Blender green-up conversion; per-actor shader duplication is not required.

Provisional presentation values: radius420 world units,height170; cold ambient(.40,.54,.68); exponential radial falloff with direct coefficients.56/1.65; highlight shoulder.82/strength.55; emission gain.70; final glow threshold.45,intensity1.0,bloom.08,Screen blend. No gameplay power,damage,spawning,capacity or timing values changed.

`final-source-identity.json` records exact source hashes over base `ff1de6d` plus disjoint accepted/recovered work. This lane changed `project.godot`, the application viewport setup hook, `release_view.gd`, new `src/presentation/lighting/` helpers/shaders, and task-specific probes/evidence. Existing icon ordering was preserved. It did not edit the three planning logs or commit source. The source and runtime lease were released to Astra immediately after selected native verification; remaining edits are documentation/evidence only.

Reproduce independently without overwriting retained captures:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/reviews/presentation-v3/T-081/run-probe.ps1 -ProjectPath . -Label reviewer-native -EvidenceDirectory res://.godot/release-qa/t081-reviewer -Script res://tests/presentation/capture_t081_lighting.gd
```

The runner now honors the project-selected backend by default; an explicit `-Backend mobile` or `gl_compatibility` is available for comparators. Capture scripts also accept `-- --evidence-dir=<path>` directly. Motion playback uses recorded timestamps in `motion/mobile/timestamps.json`; open the adjacent `index.html` to view the native lossless sequence. No generated art or upscaled render substitutes for these native captures.

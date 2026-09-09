# T-081 — RC2 control failed the retained maximum-frame gate

Owner Sol. Recorded 2026-09-09 UTC (2026-09-08 local). **Partial delivery; STOPPED before lighting implementation.**

The first unmodified RC2 control measured a maximum frame interval of **21.760 ms**, exceeding the approved **20.3379 ms** ceiling. Median, p95 and simulation/wall ratio passed. This is a failure to reproduce the retained envelope on the unchanged reference, not evidence of a lighting/backend regression. No second sample, lighting edit, Mobile comparator or downstream implementation followed the breach. Astra was notified immediately and the exclusive runtime/source/assets freeze released.

## Every sample

| Metric | Archived RC2 | Approved ceiling/floor | RC2 control 01 | Result |
|---|---:|---:|---:|---|
| Median frame interval, ms | 16.668 | <=18.3348 | 16.664 | PASS |
| p95 frame interval, ms | 16.760 | <=18.4360 | 16.751 | PASS |
| Maximum frame interval, ms | 18.489 | <=20.3379 | 21.760 | **FAIL** |
| Simulation/wall ratio | 0.999980667 | >=0.99 | 1.00000333334444 | PASS |

Maximum interval is 17.69% above the archived maximum, 6.99% above the allowed ceiling. Diagnostic median draw=1.052 ms, sync=2.465 ms, quote=0.008 ms, maximum simulation callback=4.523 ms. These callback figures are not GPU-frame timings. The one sample is retained in full in `rc2-matched-01.stdout.log` and `.engine.log`; no average hides its failure.

## Identity and environment

- Untouched reference: `ebeaf7211c76d4e34d5101025804c439a082fb48`, extracted with `git archive` into `.godot/release-qa/t081-rc2/`; ZIP SHA256 `53B5611AFBD3A9AC4624501F699AB0086EB0D743DA8511080D72BF3DE101B6C3`.
- Active checkout at handoff: `7a85a88ab5ac2a00fd6bdf6e2c756542fbdd22a4`. Existing `project.godot` icon-order-only diff and C/F/Astra changes preserved. No runtime files changed by this delivery.
- Native engine `4.7.2.stable.official.ed1daf0bf`; OpenGL 3.3 Compatibility, RTX 4080, NVIDIA driver 610.88. Historical hardware/driver match.
- Root confirmed C/F source/assets/GPU freeze, no audio generation/Blender rendering, editor closed and no other Godot owner. Runner checked for competing Godot before launch. Import PID4580, timed PID19476; both exited0 without timeout or script/parse error. No owned Godot process remained after the trial.
- `nvidia-smi` immediately before launch reported P8, 48% GPU utilization and 38 C. This is a single pretrial observation without attribution; it does not establish the source of the maximum interval. No process was stopped based on that observation.
- Original `tests/performance/measure_release.gd` unchanged: actual 2560x1440 application stage, 12 rings, 128 durable active machines, effects enabled, zoom0.41, 60 warmup process frames, 180 measured process frames, fixed-step clock60 Hz. Fresh isolated profile; original default UI scale. No vsync/pacing override or uncapping flag.
- The original probe does not pin/report the randomized star palette or RNG seed, exact initial/end simulation ticks, nor record every raw frame timestamp. Those remain **unrecorded**, not inferred. Camera uses the original scene default followed by its existing zoom/force-update calls. This control deliberately preserves that historical probe unchanged; matched visual captures would need a separately documented deterministic probe.
- Process commands, UTC boundaries and isolated APPDATA/LOCALAPPDATA paths are recorded in `*.command.json`. System-certificate-store read diagnostic occurred in both import and trial, as in prior baseline runs; no script/parse failure followed it.

## Reproduction commands

```powershell
git archive --format=zip --output=.godot/release-qa/t081-rc2-source.zip ebeaf72
Expand-Archive -LiteralPath .godot/release-qa/t081-rc2-source.zip -DestinationPath .godot/release-qa/t081-rc2
powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/reviews/presentation-v3/T-081/run-probe.ps1 -ProjectPath .godot/release-qa/t081-rc2 -Label rc2-import -Import
nvidia-smi --query-gpu=name,driver_version,pstate,utilization.gpu,temperature.gpu --format=csv
powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/reviews/presentation-v3/T-081/run-probe.ps1 -ProjectPath .godot/release-qa/t081-rc2 -Label rc2-matched-01 -Script res://tests/performance/measure_release.gd
```

The bounded runner uses `Start-Process -WindowStyle Hidden`, retains the native handle, records exact exit status, rejects concurrent Godot, and fails closed after any reported performance breach. The harness exits1 for the gate even though Godot's correctness checks exited0.

## Acceptance matrix and next owner action

| Check | Status |
|---|---|
| Untouched RC2 control imported with pinned engine | PASS |
| First native control within every retained limit | **FAIL: maximum frame interval** |
| Three paired runs / uncapped diagnostics | NOT RUN: stopped after first breach |
| Unlit capture / six-ring all-palette before-after | NOT RUN: stopped after first breach |
| Compatibility lighting/material/cache/glow proof | NOT STARTED |
| Matched Mobile comparator/backend selection | NOT STARTED |
| Pan/Alt/cache/motion proof | NOT RUN |
| Integrated 42+ native correctness suites | NOT RUN: no production implementation |
| Rendering adapter handoff / final art acceptance | NOT READY |

Proposed next step for Astra/Kevin review: authorize a bounded investigation of the unchanged RC2 failure, with individually retained samples and pretrial/runtime system-load observations. Do not rebaseline, loosen limits, attribute the hitch to noise without evidence, or resume production/downstream work through this failed gate. No numeric presentation tuning values were introduced. This evidence is a narrowly scoped partial patch, not an accepted task commit.

## Authorized read-only load investigation after reporting

At 22:45:00 local, NVIDIA reported 50% GPU utilization while in P8 at 225 MHz graphics / 405 MHz memory, drawing 24.11 W. A percentage at these low clocks does not by itself establish heavy load or explain the measured hitch. The NVIDIA context list includes `TheyAreBillions.exe` PID16276 as well as Blender, shell/desktop components, PowerToys and other applications. A listed context does not establish active rendering; this is a posttrial snapshot, not a time-correlated attribution. Per-process GPU memory is unavailable under this output, and Windows per-engine utilization lookup failed with `Access denied`. No process was closed, no settings changed and no additional benchmark run.

The concrete next diagnostic should first establish whether that other game is actively rendering and request Kevin to save/close it if so, then collect a bounded individual RC2 control with load telemetry. Keep the failed first control in the evidence even if subsequent samples pass. Do not claim the other game's presence caused this failure without measurements. Read-only outputs and the explicit access limitation are retained in `gpu-after.txt`, `gpu-compute-processes-after.txt` and `gpu-engines-after-unavailable.txt`.

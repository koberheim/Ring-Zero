# T-068 — Final integration and private package verification

## Pre-T-071 aggregate retained

Source owners froze and root transferred exclusive runtime at2026-09-08T10:50:57.3264206Z (recorded receipt/start). Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_tests.ps1`.

**38/38 discovered suites passed**, runner PID40328 exit0. Pinned version PID38368 and import PID45736 both exited0; import took2.898seconds. All40 owned Godot launches were hidden/tracked, with10-second version and90-second import/per-suite bounds, readable exit0 and no timeout. Workspace APPDATA/LOCALAPPDATA remained isolated and restored by the runner. Individual summaries/counts/exits/timeouts/log paths: `.godot/test-logs/run-20260908-105058-185-40328/summary.json`.

Log audit completed by10:53:00.2631095Z. No script/parse/shader errors. General errors were the known certificate-store startup diagnostic and intentional invalid-input PolarGrid/EntityPool/FixedStepClock checks. Import also warned that the earlier source-snapshot nested project was ignored.

During this run root found a separate native-image defect: strategic empty-slot beads and labels overlapped. The aggregate completed against the existing source before Luna received T-071's edit/runtime handoff. Thus this is accepted **pre-T-071** evidence, not final verification of the display correction. All owned processes exited; no export or native package smoke was started. Final aggregate/export awaits T-071 freeze. Existing full matrix performance evidence and limitations are in [T-068-performance.md](T-068-performance.md).

## Prepared package verification

`scripts/export_private.ps1 -FrozenSource` imports first, generates the source identity, exports with installed pinned Mono templates, then verifies source inventory membership and hashes. A changed source or generated sidecar refuses a stale frozen identity. Final candidate must retain adjacent PCK/build metadata/font notices.

`scripts/smoke_private.ps1` is a reviewed external Windows input driver, not an embedded game testing hook. It confines native SendInput batches to its own verified foreground HWND/PID, aborts on focus changes or held user modifiers, and uses fresh isolated APPDATA/LOCALAPPDATA. Expected sequence is actual Start, modest real play, Flak key plus valid world slot, cancellation, pause/resume/pause, explicit Abandon, Quit and independent relaunch/Quit. Assertions inspect the real trace/profile for an accepted command, pause markers, progressed ticks, abandoned end, zero reward, frozen build ID and unchanged reloaded profile bytes. Inputs/launches/exits are logged. Driver/focus aborts are distinguished from product errors and unresolved verification failures. No grants, normal-game debug hooks or unrelated process kills exist.

## Final T-071 aggregate

Root accepted the final strategic-detail correction and transferred the frozen source/runtime window. Recorded receipt/start: **2026-09-08T10:57:48.7903182Z**. The same native runner command passed **39/39 discovered suites**, runner PID27708 exit0; version PID7600 and import PID43040 exit0 (import2.519seconds). All41 tracked children exited with no timeout. Per-suite counts/exits and paths are in `.godot/test-logs/run-20260908-105749-616-27708/summary.json`. This includes final strategic-detail, application/recorder, progression, persistence, numerical movement and existing regression suites; no baseline was regenerated.

Final log scan found no script/parse/shader errors. General errors are the certificate-store startup diagnostic and deliberate invalid-input PolarGrid/EntityPool/FixedStepClock cases. Import warned only about ignoring the earlier nested source snapshot. Workspace caches were isolated/restored; unrelated editors remained untouched.

## Final frozen private package

Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/export_private.ps1 -FrozenSource`. Final version PID39756, import PID4068 and export PID30924 all exited0. Installed Mono4.7.2 editor/templates successfully exported this GDScript application. The executable is `exports/windows/RingZero.exe` (109,513,728bytes), with adjacent `RingZero.pck` (518,268bytes), `build_info.json` and bundled font notices under `licenses/`. No installation or publication occurred.

Frozen source identity: `b1df72c682cb1405d76422f67998cfdbffc2e858662c6a1b120e0507bd4f8fb3`, **221 inventoried source files**. Manifest generation followed import; export and a separate post-smoke `scripts/verify_build_info.ps1` verified every current source hash and inventory membership. Reports/documentation are excluded from executable identity; the final source snapshot includes generated metadata.

## Actual packaged lifecycle and limits

The global SendInput driver aborted twice before sending any input because the owned game window could not satisfy its foreground guard (PIDs40868 and39852). A read-only check returned foreground HWND0; cause was not established. The guard was preserved. The attempted external SceneTree `--script` driver did not run in the release package: PID42364 produced no driver entry/evidence and reached its40-second bound. Release help PID11272 exited0 without a script option. These are driver/template limitations, not passing lifecycle evidence or demonstrated product failures; no further retries used those paths.

Root approved the separate `scripts/smoke_targeted.ps1` driver. It addresses Windows mouse/key messages only to the verified live owned HWND/PID, checking ownership before every message. It uses no global input, fake focus, injected code, game-state grants or embedded product hook. After adding the driver, the source identity and package were regenerated as above.

Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/smoke_targeted.ps1`. **Passed**, driver exit0; first game PID29180 and independent reload PID16568 both exited0 through the real Quit button. Evidence: `.godot/package-targeted/run-20260908-111224-267-39960/summary.json`, alongside native logs and isolated profile/run trace.

Real packaged actions were Start, Flak hotkey/world placement, cancellation, pause/resume/pause, explicit Abandon, Quit, independent reload and Quit. The accepted `place_build` command targeted ring1/wedge3/slot0 at tick78. Pause/resume shared tick138, second pause/end used tick154 (2.566666666666667seconds authoritative play). The trace ended `abandoned`; durable profile had run1 settled, nextID2, no pending run and zero currency. Profile bytes stayed unchanged through reload/Quit. The trace matched the frozen build identity. Both package logs contained only the certificate-store diagnostic, with no script/parse/shader errors.

This verifies the exported main scene and real application input dispatch using **owned-window messages**. It does not establish global OS foreground routing, human usability, sustained swarm capacity or packaged reward/shop coverage; focused application suites cover reward/shop separately. All owned processes exited. Performance limits remain explicit in [T-068-performance.md](T-068-performance.md), including the costly mixed swarm and separate rendered measurements.

Final results were delivered to root before snapshotting. A source snapshot is generated after root's documentation freeze so it captures the completed briefing; the final handoff identifies its exact inventory path.

# Correctness checks on Windows

From PowerShell, run:

```powershell
& 'E:/AI Projects/Games/Ring Zero/scripts/run_tests.ps1'
```

The project root comes from the script's location, so the current directory does not matter. The default executable is `E:/Godot/Godot_v4.7.2-stable_win64.exe`; the runner checks its exact reported version, `4.7.2.stable.official.ed1daf0bf`. Windows PowerShell 5.1 or PowerShell 7 on Windows is required. No Bash or GNU timeout is needed. If your local execution policy requires a process-scoped invocation, use `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_tests.ps1`; this changes no persistent policy.

```powershell
& ./scripts/run_tests.ps1 -GodotExecutable 'E:/Godot/Godot_v4.7.2-stable_win64.exe' -SuiteTimeoutSeconds 120 -ImportTimeoutSeconds 90
```

The runner verifies the executable, project file, and nonempty recursive `tests/**/test_*.gd` discovery before launching Godot. It checks the engine version, imports the project with `--headless --editor --import --quit` to populate global classes, then runs suites sequentially. Each child process is hidden, tracked by its process object, and bounded by a timeout. Only the child it started is terminated on timeout. Version discovery has a ten-second timeout; import and each suite default to ninety seconds. Executable paths containing spaces are supported.

APPDATA and LOCALAPPDATA are redirected only for this runner and its children to `.godot/appdata` and `.godot/localappdata`, then restored in the runner process. No cache cleanup or global environment modification occurs. Every invocation retains a separate `.godot/test-logs/run-<UTC timestamp>-<PID>/` directory containing engine logs, stdout, stderr, and a per-suite `summary.json`. Nonzero exits, timeouts, and `SCRIPT ERROR:`/`Parse Error:` diagnostics fail a suite. Expected validation `push_error` diagnostics are not blanket failures; suites remain responsible for their assertions and nonzero failure exit. A startup/import failure aborts before suites. Exit codes: 0 = all discovered suites passed; 1 = suite failure; 2 = prerequisite/version/import failure. An empty discovery never succeeds.

The runner excludes standalone `capture_*.gd` and `benchmark_*.gd` scripts and does not request `--cost-*` modes. **Some ordinary correctness suites still execute internal timing blocks.** This runner does not remove them, isolate their CPU measurements, or certify performance results. Run dedicated headless or rendered performance commands separately in an exclusive Godot window, using the relevant task's documented fixtures. Close unrelated editor/capture/benchmark sessions before using those measurements as evidence. This correctness task changes no test fixtures or baseline digests.

`bash scripts/run_tests.sh` remains the legacy option for existing Bash/GNU timeout setups with an already-imported project. It does not provide the native runner's import/version/discovery safeguards; the PowerShell command above is the supported reproducible Windows entry point. Neither correctness runner exports the game. The September 8 feature-completion authorization adds the separate private tooling below.

## Private Windows build

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/export_private.ps1` uses the installed pinned Mono 4.7.2 editor and matching Windows templates, with hidden tracked bounded launches and workspace caches. The preset records this workstation's template paths; no installation or publishing occurs. Output is `exports/windows/RingZero.exe` with its adjacent PCK and license notices. Keep the directory together. Final application verification requires an export after all source owners freeze; an intermediate tooling smoke is not the final candidate.

After an explicit source freeze, add `-FrozenSource`. The exporter imports first, generates `data/build_info.json` from sorted source hashes, exports, then verifies inventory membership and every source hash again. It refuses a stale identity if import/export or concurrent edits change source; regenerate and re-export after resolving the change. Generated metadata and logs are excluded from their own identity. Default exports mark `frozen:false`; editor-run recorder headers always say `development-unfrozen`. Standalone checks: `scripts/write_build_info.ps1` and `scripts/verify_build_info.ps1` (neither launches Godot). The final snapshot includes generated metadata.

## Source snapshot

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/snapshot_source.ps1` creates `exports/source-<UTC timestamp>/` and a sorted `inventory.json` with relative paths, byte lengths and SHA256 hashes of the copied files. It excludes caches, previous exports, user profile files, review captures, logs and VCS/agent metadata. Run after source freeze for a coherent release snapshot; copying while owners edit is only a tooling check. The snapshot is not a Git commit and does not include user progress.

# T-063 — Post-Phase-9 baseline and persistence readiness

Sol, 2026-09-08. **30 discovered suites passed, zero failures.** Only this report was written. No source/test/profile change, baseline regeneration, export, installation or unrelated editor interaction occurred.

## Actual baseline run

Root authorized the exclusive task runtime window. Receipt/start was recorded at **2026-09-08T09:48:47.2857459Z**. Command from project root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

Runner PID 5420 returned **0**. Pinned `E:/Godot/Godot_v4.7.2-stable_win64.exe` returned `4.7.2.stable.official.ed1daf0bf` (PID 31496). Clean import preparation (PID 45540) passed in 2.708 seconds using `--headless --editor --import --quit`; existing caches were preserved. Workspace APPDATA/LOCALAPPDATA were process-local and restored by the runner. Version timeout 10 seconds; import and each suite 90 seconds. Hidden tracked launches retained process handles and actual exit codes.

All 32 launched Godot processes exited 0, with no timeout, missing exit code or termination. Runner completion and summary verification preceded **09:49:50.0548024Z**. Runtime window was released to root; unrelated editor processes were untouched.

Individual suite summaries, actual exits, elapsed times and timeout flags are retained in `.godot/test-logs/run-20260908-094848-162-5420/summary.json`; that directory also contains engine/stdout/stderr logs and version/import evidence. All 30 rows report Passed=true, ExitCode=0 and TimedOut=false.

| Group | Individual suite check counts (all zero failures) |
|---|---|
| Core | polar_grid 1206; polar_motion PASS; polar_route_field 287; simulation_foundation PASS |
| Gameplay | ability_rules 30; assembler_rules 42; balance_profile 580; breacher_rules 49; building_rules 76; foundry_rules 50; live_simulation 702; machine_spawn_rules 151; sapper_rules 49; terrain_rules 48; transfer_rules 49; tunneler_rules 224; wall_navigation 507; wall_rules 97; weapon_rules 409 |
| Presentation | art_preview 59; build_view 49; grid_inspection 6668; growing_world_view 58; hotkeys_compact_ui 418; live_view 85; structure_view 13; terrain_ability_view 116; tunneler_view 47; wall_view 84; weapon_catalogue_view 73 |

Log scan found no SCRIPT ERROR, Parse Error or Shader Error. General ERROR lines were the existing root-certificate-store diagnostic and intentional invalid-input diagnostics for PolarGrid, EntityPool and FixedStepClock. No correction/rerun was needed. Embedded timing output is incidental to correctness: this report makes no new performance, capacity or final-art claim.

## Read-only readiness findings

- No `user://`, ConfigFile or save implementation occurs in current `src`. The only FileAccess usage found is balance JSON loading (`src/gameplay/balance_profile.gd:159`). `LiveSimulation` stores `core_hp`, elapsed time and ended in memory (`src/gameplay/live_simulation.gd:31`); presentation resets its own kill count on new run (`src/presentation/live_view.gd:92`). There is no durable run identifier or reward receipt. Presentation totals alone are not a durable settlement boundary.
- `export_presets.cfg` is absent. The pinned non-Mono executable exists. The inspected user template directory, `E:/Users/Kevin/AppData/Roaming/Godot/export_templates`, contains only `4.7.2.stable.mono` Windows debug/release x86_64 binaries and console companions. The workspace `.godot/appdata/Godot/export_templates` directory contains no files. Matching non-Mono templates were not found in these locations; no claim is made about every disk location or compatibility of the Mono binaries. Establish a pinned Windows export prerequisite before promising a reproducible standalone build.
- `assets` currently contains four art mockup PNGs and their import metadata. No tracked TTF/OTF or font license was found. `build_view.gd:426` and live warning drawing use `ThemeDB.fallback_font`; Windows Fonts has installed TTFs such as AGENCYB.TTF and ANTQUAB.TTF, but local presence is not evidence of redistribution permission. Retaining the current engine fallback avoids introducing an unverified font dependency; any later bundled font needs its license recorded.
- `project.godot` still starts `scenes/live_view.tscn`, uses GL compatibility and has no export configuration. Readiness inspection did not execute an export or validate a packaged build.

## Recommended bounded profile contract

Implement a small application-owned service, separate from simulation rules. Use a versioned JSON envelope containing `schema_version`, monotonically increasing `revision`, validated `settings`, validated `meta`, and one durable active-run record with its monotonically allocated identifier and settlement state. Store large identifiers as canonical decimal strings if JSON number conversion would lose integer precision. Reject unsupported future versions without overwriting them; migrate known older versions on a cloned candidate.

Minimal public API: `load_profile()`, `snapshot()`, `update_settings(patch, expected_revision)`, `begin_run(expected_revision)` and `settle_run(run_id, result, expected_revision)`. Return structured success/errors and independently cloned snapshots. Validate finite numeric bounds, exact types, allowed keys and overflow at every public boundary. Settings/meta mutations must not edit live simulation state implicitly. Route all writers through one service; reject stale revisions and concurrent application writers rather than silently losing updates.

For persistence, serialize a completely validated candidate to a sibling temporary file, check write/flush/close outcomes as available, reopen and validate it, then use a tested same-filesystem replacement protocol while retaining a known-good backup. Commit the in-memory candidate only after successful disk commit. Do not delete the sole valid copy before replacement. Define deterministic startup recovery for main/temporary/backup revisions and test each interruption point on Windows; do not claim power-loss durability merely because a rename succeeded.

Allocate/persist the run identifier before gameplay begins. Settlement must atomically store both the reward/meta change and that run's settled receipt in the same envelope. Repeating the same settlement returns the existing receipt without granting again; conflicting results for the same identifier fail. For a single active run, retaining the current/last receipt plus a monotonic high-water mark can reject old identifiers without an unbounded receipt list; never prune identifiers in a way that makes an old replay eligible. Bind reward calculation to authoritative run-result data, not an arbitrary UI-supplied amount.

This makes retries idempotent after a durable settlement attempt. It does not itself guarantee a reward for a result lost in a crash before any result record was persisted. If that guarantee is required, persist a completed-result journal before allowing Retry/exit to discard the run, and recover settlement on startup. Define abandoned-run behavior separately from completed-run rewards.

Implementation milestones: (1) pure schema/migrations and clone/validation tests; (2) injected storage failure and startup recovery tests, including unsupported versions; (3) begin/settle service with repeated/conflicting/stale settlement tests; (4) settings and run-end UI wiring with visible save errors and retry; (5) pinned Windows preset/templates and a fresh-user packaged smoke test. Test corruption, failed writes, interrupted replacement, repeated settlement after restart and two writers explicitly. Full run resume is a separate larger serialization contract and should not be implied by settings/meta persistence.

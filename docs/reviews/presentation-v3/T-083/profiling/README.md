# Dense collapse profiling preparation

Execution update: the coordinated window completed with import and ten retained native trials. See [diagnosis.md](diagnosis.md): whole paired-cache refresh is the primary source of the reproduced100–120ms stalls; no production repair or gate waiver occurred. Runtime/freeze was explicitly released afterward. The preparation/run instructions below remain for the next assigned profiling owner; request a new coordinated window before further engine or heavy work.

The planned archive is exactly `67a49cb`, under `.godot/release-qa/t083-profile-base`. Create a fresh git archive there only if the target does not already exist. Use native PowerShell directory creation and extraction; no recursive move/delete is needed. `prepare.py` refuses any other target and a second instrumentation pass. It edits only this isolated archive, saving original source and instrumentation hashes. Current root views, gameplay and effects files are never edited.

Archive preparation, once the window is granted:

```powershell
git archive --format=zip --output=.godot/release-qa/t083-profile-base.zip 67a49cb
New-Item -ItemType Directory -Path .godot/release-qa/t083-profile-base
Expand-Archive -LiteralPath .godot/release-qa/t083-profile-base.zip -DestinationPath .godot/release-qa/t083-profile-base
python docs/reviews/presentation-v3/T-083/profiling/prepare.py '.godot/release-qa/t083-profile-base'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/reviews/presentation-v3/T-083/profiling/run.ps1 -Mode import -Label import-01
```

Then run individual unique labels/modes through `run.ps1`: `normal`, `draw-off`, `admission-off`, `cache-hold`. Do not batch blindly across a parse/fixture error. Each process repeats the same initial state twice, recreating the live view while retaining the process/device; that tests within-process first-use differences and is **not** a cold machine/driver-cache claim. Every launch snapshots all instrumented source and its hashes before engine startup. Existing attempt labels are rejected.

The fixture retains dense04's actual setup: release profile with spawn0, Flakdamage0, power output1800; funded twelve-ring public expansion, six prior broken wedges, wedge7 initially6.7HP; public15Flak/10armor/95RepairNodes/fiveWalls on ring12;128 diagnostic actors, one initially stunned1.1s then1e7DPS attacker and127 almost stationary zero-DPS actors. Preflight verifies actual placement results, state validity and all occupancy counts before timing. Every mode must preserve initial state/target hashes and actual ring12 collapse at tick67. No natural-production play claim is made.

Modes change only isolated presentation behavior:

- Normal: instrumented baseline, all feedback enabled.
- Draw-off: keeps geometry admission/aging/impulse and disables only collapse drawing.
- Admission-off: suppresses the cosmetic geometry admission, consequently also no debris/impulse; simulation and fortress invalidation remain.
- Cache-hold: stops static cache refresh after60 warmup frames. The displayed fortress becomes deliberately stale. This is strictly a cache-cost diagnostic, never an acceptance capture or proposed fix.

Timeline fields retain wall frame intervals, simulation ticks per draw, existing simulation/sync/draw/quote CPU counters, geometry hook CPU, effect draw-submission CPU, cache checking CPU, paired albedo/material rebuild CPU and counts, actual state-copy CPU and repair-node CPU. Values in microseconds are CPU timings; none are presented as GPU durations. Native draw counters can lag the current simulation tick by one render phase, so inspect neighboring timeline rows when correlating spikes. No image readback, PNG save, JSON serialization, filesystem writes or console print occurs inside the measured loop. The extra counters/dictionaries add diagnostic overhead equally across modes; canonical performance remains a separate unchanged fixture.

Original diagnostic question: isolate whether the111.127ms spike follows simulation/repair-node cost, snapshot admission, cache rebuild, immediate draw submission or first-use rendering/device work. The completed comparisons and their limits are now recorded in diagnosis.md; the original failed samples remain intact.

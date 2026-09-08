# T-012 — Fixed-step clock, reusable entity storage, and crowd measurements

**Owner:** Sol. **Date:** 2026-09-06. **Coordinator:** Astra.
Kevin approved 60 simulation updates/second, normal path behavior, and temporary 2 arrivals/second tuning. He explicitly expects hundreds/thousands of concurrent enemies in final gameplay (They Are Billions reference). This task establishes generic clock/storage and measures scale, not a final cap or enemy simulation.

## Files

Own src/core/fixed_step_clock.gd, src/core/entity_pool.gd, tests/core/test_simulation_foundation.gd, tests/performance/benchmark_crowds.gd, docs/reviews/T-012.md. Adjacent .uid allowed. Read this brief only and your own files. No full spec/logs or unrelated source reads; required public API is below. No scene, gameplay, balance, pathing, or presentation edits; no delegation.

## EntityPool API

EntityPool extends RefCounted; constructor _init(capacity:int), nonnegative capacity required; negative emits clear diagnostic and behaves as zero capacity.
- var capacity:int (read-only by convention)
- func spawn(payload:Dictionary) -> int
- func release(id:int) -> bool
- func contains(id:int) -> bool
- func payload_for(id:int) -> Dictionary
- func active_ids() -> PackedInt64Array
- func active_count() -> int

Preallocate reusable record slots at construction; keep an O(1) free-slot list and ID-to-slot lookup. Spawn returns a nonnegative monotonically increasing lifetime ID, or -1 if full (no mutation on failure). Never recycle an ID after release. This makes stale target/event IDs fail even when storage slots are reused. Handle ID exhaustion clearly rather than wrap.
Each slot owns a reusable payload Dictionary. Copy incoming Dictionary values into it, without retaining the caller's top-level container. Payload values may include live mutable domain objects; this generic pool does not clone or interpret those objects. payload_for returns a live dictionary for a current ID, empty dictionary for a missing ID. Callers must look up by ID and not retain live payload references after release. Release clears all values and returns the slot to the free list; double release returns false. active_ids returns an independent ID array in a documented deterministic order, and active_count remains correct after reuse.
Do not store Cartesian positions or introduce enemy health/rules in the engine API. The game will own its polar payload.

## FixedStepClock API

FixedStepClock extends RefCounted; constructor _init(tick_hz:float, on_tick:Callable).
- var paused:bool = false
- var tick_count:int = 0
- func advance(delta_seconds:float) -> int
- func elapsed_seconds() -> float

A valid rate is finite and positive and callback must be valid. Invalid construction emits diagnostic and leaves an inert clock; invalid delta (negative/nonfinite) emits diagnostic and advances nothing. Each complete accumulated step calls on_tick with step seconds exactly once. Count complete steps; elapsed_seconds = tick_count / tick_hz. Fractional remainder survives calls. While paused, do not call the callback or accumulate time for later catch-up. No dropped simulation time, variable-size tick, hardcoded machine limit, scene processing, or renderer. Protect floating subtraction boundaries with documented numerical tolerance; a 60Hz clock given one second in varied partitions must deliver 60 ticks.

## Tests and benchmarks

Focused tests exit nonzero on failure: zero/full capacity, live lookup and top-level input isolation, release/reuse with stale-ID rejection, independent active-ID list, repeated churn and count consistency; clock partitions, 60-tick second, pause/resume with no catch-up, invalid inputs and callback count. Verify slots are reused without growing the record store (a small debug/inspection property may expose allocated_record_count, documented).

Benchmark capacities 500, 1,000, and 5,000. Report spawn/release/reuse and iteration cost, with warmup and median/tail elapsed times. Do not select a live cap from this microbenchmark.

Also measure the CURRENT automatic-combat function against 500/1,000/5,000 supplied targets in a documented representative test state (one ring with its 11 non-relay slots armed). This exposes whether the current simple targeting approach needs work before the intended crowd scale. Do not optimize or edit Terra's rules in this task.
Known API:
BalanceProfile.load_json("res://data/balance/testing.json") -> {ok,profile,errors}
BuildingRules.create_default_testing_state(profile) -> {ok,state,errors}; state.energy may be set in a benchmark fixture only.
BuildingRules.place_weapon(state,profile,ring,wedge,slot,kind:StringName)->{ok,state,errors}
WeaponRules.step(state,profile,targets:Array[Dictionary],cooldowns:Dictionary,delta_seconds:float) -> {ok,targets,cooldowns,hits,kill_ids,energy_awarded,errors}
Target {id:int>=0,position:PolarPosition,hp:finite>=0}; constructor PolarPosition(ring,wedge,radial_fraction,angular_fraction). Use evenly distributed wedge IDs1–12 on band2, fractions [0,1); substantial finite HP prevents benchmark kills changing the workload. Tick delta=1/60. Empty cooldowns each benchmark sample measure a ready volley; document that this stresses target search rather than simulating a live run. Keep original input data intact.

Use a small repeat count (e.g. 3 warmups and 10 measured samples per crowd) so this remains bounded; report sample count and workstation CPU/GPU if available through read-only inventory. Record whether rendering was absent. Never claim full-game FPS from a headless measurement. If a sample is very slow, finish a smaller documented set rather than run indefinitely.

Godot E:/Godot/Godot_v4.7.2-stable_win64.exe; APPDATA/LOCALAPPDATA redirected per process under workspace .godot; local log files. Import and run focused tests/benchmarks only. Record exact commands, timings, and limitations in docs/reviews/T-012.md. Stop for Astra review. No final cap, live loop, spawning, navigation, or gameplay integration in this task.

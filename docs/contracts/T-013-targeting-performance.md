# T-013 — Remove repeated work from automatic target selection

**Owner:** Terra. **Start:** after T-010 acceptance; current interface/rules remain fixed.
**Evidence:** T-012 measured eleven ready Flak against evenly distributed durable targets. Median ready volleys: about 8.9 ms at 500, 18.8 ms at 1,000, 106.6 ms at 5,000, headless. This is not full-game FPS. Do not choose a cap or alter targeting/gameplay to fit a budget.

## Own and change

src/gameplay/weapon_rules.gd, tests/gameplay/test_weapon_rules.gd, docs/reviews/T-013.md only; generated metadata as needed. Read your own files and tests/performance/benchmark_crowds.gd ONLY if needed to run/understand the benchmark; no other source edits. No new dependencies, threading, gameplay changes, target loss, lower density, or lower update rate. No delegation.

Cache each validated supplied target's derived world position once per step instead of repeating polar conversion for every weapon. Preserve cloning, mutable HP propagation between weapons, and all validation/error/result contracts.

Avoid fully sorting all eligible targets when only the nearest few are needed. Use an exact bounded selection for small max_targets, preserving distance then ID ordering; retain a general fallback if necessary for large data-driven caps. Do not hardcode a gameplay target limit or stop considering candidates. Keep existing range/arc tolerance and distance-tie semantics. Do not approximate spatial queries or alter arcs, damage, cadence, rewards, or ordering.

## Verify before delivery

Run existing weapon rules and add meaningful behavior-equivalence checks against an independent straightforward reference selector in tests: varied polar target bearings/distances, duplicate-distance IDs, dead targets, tuned arcs/ranges/caps including caps above the small-selection path, multiple weapons and same-step kills, and input isolation. Preserve exact selected IDs, hit order/damage, cooldowns, and rewards. Do not add tests that just mirror the optimized loop.

Rerun the SAME benchmark command/fixture: tests/performance/benchmark_crowds.gd, three warmups/ten samples at 500/1,000/5,000. It measures pools too; don't edit its setup to improve results. Record before/after targeting median/p90 and sample counts, noting headless/11-Flak/ready-volley limitations. Stop if a change regresses correctness; return the finding, not a weakened test.

Use pinned Godot and workspace APPDATA/LOCALAPPDATA and --log-file paths. Record actual tests and benchmark evidence in docs/reviews/T-013.md. No final density/FPS/cap claim. Astra reviews the changed implementation and independent comparisons before acceptance.

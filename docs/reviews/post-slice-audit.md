# Post-slice audit and readiness assessment

2026-09-07. Astra review requested by Kevin after Claude completed Phase 5. Scope: current code, tests, design specification, decision records and evidence; plan the remaining full game for private testing, not publication. No gameplay or presentation implementation was changed in this audit.

## Verdict

Phases 1-5 are complete **within their approved vertical-slice scope and accepted exceptions**. D-081 accepts the current performance shortfall for testing, D-082 accepts Phase 4, and D-084 accepts the limited Kevin-only engineering evidence. These approvals stand. They do not establish full-game readiness, a successful 15-25-minute run, fun, recovery quality, power comprehension or run variety.

The current executable is a three-ring technical prototype with a working purchase/combat/loss loop and a persistent HUD. It is not yet a complete repeatable game session. Most absent systems are deliberate slice deferrals, not missed implementation promises. Two concrete correctness/coverage issues and an evidence error were found below.

## Independent verification

- All **17** current `test_*.gd` suites in core, gameplay and presentation exited 0 under Godot 4.7.2 (`ed1daf0bf`). Fourteen suites reported **10,311 checks**, zero failures; the remaining three reported PASS without aggregate counts. Do not count these as additional invented assertions.
- Presentation results: grid inspection 6,668; build 49; live/HUD 71; walls 84; Tunnelers 47. Gameplay: balance 432; building 45; live simulation 404; normal spawning 147; Tunnelers 224; walls 97; navigation 480; weapons 357. Polar grid: 1,206. Polar motion, route field and simulation foundation: PASS.
- Each suite ran separately, sequentially, in a hidden tracked process with a 30-second timeout and workspace APPDATA/LOCALAPPDATA. Logs are `.godot/post-slice-audit-test_*.log`. Expected negative-input diagnostics in the clock suite and the known root-certificate-store diagnostic are not failed assertions.
- Inspected both actual T-029 PNGs. No new rendered performance claim is made; the accepted historical measurements remain the evidence. Routine tests that include timing were used for correctness only.
- A separate non-production probe reproduced findings A1 and A2. Source: [post-slice-audit-probe.gd](artifacts/post-slice-audit-probe.gd). Run with `Godot --headless --path . --script docs/reviews/artifacts/post-slice-audit-probe.gd`. It intentionally exits 0 when it reproduces the current defects; it is evidence, not a future regression test asserting correct behavior.

## Findings, in priority order

| ID | Classification | Finding and evidence | Required follow-up |
|---|---|---|---|
| A1 | Correctness defect, latent under default balance | `src/presentation/live_view.gd:297-309` reconstructs maximum HP from the profile instead of reading each wedge's authoritative `max_hp`. State validation accepts HP 50/max HP 400 at ring 1, but the HUD reports `ok` rather than 12.5%-HP `critical`. The probe confirmed `state_valid=true`, `actual=ok`. | Read authoritative maximum HP. Test below/at/above the 25% boundary on outer rings and with a valid maximum different from the base profile. This becomes essential before Armor Plating. |
| A2 | Integration/coverage gap beyond the playable slice | `tests/presentation/capture_ring_status_hud.gd:34-45` creates twelve simulation rings without expanding the view's three-ring grid. Probe: `rings=12 world_grid=3 selected=(12,12) world_cell_at_focus=(-1,-1)`. The minimap capture proves status rendering, not a playable twelve-ring world. | Add an integrated larger-world fixture and synchronized geometry, world selection, building, camera and HUD focus as playable rings grow. Preserve the accepted three-ring slice and the distinct, accepted density limitation. |
| A3 | Evidence error | `docs/reviews/phase-5-evidence.md:23` labels whole-ring cost divided by **one wedge's HP** as cost per HP. At ring 1, 120 energy / 1,200 total ring HP = **0.1**, not 1.2. The same corrected ratio holds at the listed radii. | Correct the units and narrow the inference. Constant cost/HP does not establish expansion balance; frontage, slots, coverage, power and income were not measured. A dated correction accompanies the accepted report. |
| A4 | Regression coverage omission | `tests/presentation/test_live_view.gd:188` onward checks broken/collapsed states and focus, not the scaled critical threshold that Claude fixed. Capture HP is low enough to pass both old and fixed formulas. | Add a discriminating ring-3 case (e.g. 50/300) and exact threshold boundaries as part of A1. Passing existing tests alone did not validate this fix. |
| A5 | Reproducibility gap | `tests/gameplay/test_live_simulation.gd:406` uses `.godot/t-023-baseline-digests.bin`; `.godot` is ignored. No source-control repository, aggregate test runner or export preset was found in this workspace. | Preserve source/build/profile identifiers and baseline provenance outside caches; provide a clean-copy test command and separate performance runs. Do not regenerate expected baselines silently from the implementation being tested. |
| A6 | Unvalidated full-game balance, not a slice defect | The current opening has 20 energy, ring 2 costs 240, arrivals are two normals/second and kills award one energy. Even killing every arrival without further spending gives a lower bound of approximately **110 seconds** to afford ring 2. Prior recorded hands-off lifetime was about **20 seconds**. One broken frontier wedge prevents expansion under D-045; there is no repair/retake yet. | Test viable player openings and a complete expansion/loss/recovery economy with approved tuning. The arithmetic is a warning, not proof that no player strategy works. The old hands-off run was not rerun in this audit. |

## What is present, and what remains

| Full-game area | Current state | Remaining work / decision gates |
|---|---|---|
| Polar world and camera | Twelve wedges, procedural geometry, fixed bearings, pan/zoom; generic core supports larger configured grids. Main game is capped at three rings. | Incremental playable growth without a design ring cap; large-world interaction and HUD readability. Hardware still has finite practical limits. |
| Economy and construction | Kill-only income; whole-ring purchase with relay; Flak, Mass Driver and Wall; automatic targeting. | Eight missing catalogue items, relay rebuilding, real power, repair and reclaim. D-027/D-023/D-022. |
| Enemy pressure | Normal machines, Tunnelers, wall routing and conditional 25% wall damage; editable testing growth/cap. | Transfer, Foundry, Sapper, Breacher, Assemblers; integrated swarm-biased pressure and counters. D-019, D-007 follow-up; existing growth is provisional. |
| Loss and comeback | Per-wedge HP, seven-break collapse, outer survivors, core defeat; no refunds. | Repair/reclaim, relay failure/rebuild, decaying assimilation. D-021/D-022/D-023. |
| Solar intervention | Absent. | Focused Flare and EMP Burst, targeting, cooldowns and damage-source reward policy. D-026. |
| Between-run progression | Absent. | Persistent rewards, upgrades, unlocks, doctrines, loadouts, mutators. D-028/D-029/D-032. |
| Player session | Main scene starts immediately; menu has Resume; defeat stops simulation. | Start/loadout flow, results, retry/new run, settings, tutorial and persistent progress. D-032/D-042/D-035. |
| Validation | Strong isolated correctness tests and accepted engineering captures. | Full-duration sessions, repeat runs, recovery/power/variety trials, representative mixed loads and reproducible private builds. |

The eight missing catalogue items plus incomplete Relay behavior are: EMP Node, Lance Emitter, Point Defense, Armor Plating, Repair Node, Debris Field, Tractor Lane, Occlusion Screen, and independently rebuildable Relay behavior. Bundled Relay and Ring Plate already exist; their full behavior still needs integration.

## Boundaries carried forward

- Do not reopen Kevin's accepted placeholder colors, twelve-ring HUD density or current 1,000-machine testing performance as retroactive slice failures. Revisit them against full-game test requirements when the game actually reaches that scale.
- Do not claim the performance cause is conclusively proven or that acceptance means the 60 Hz target was met. Historical tick costs support a catch-up explanation, but do not exclude other costs or regressions.
- Phase 5 intentionally excluded run sameness and broader participants. No invitations or external testing are authorized by this audit.
- The original design specification remains untouched. Approved overrides govern whole-ring purchases, seven-break collapse, menu pause, wall damage, Tunneler rules and swarm intent.
- [The remaining plan](../FULL-GAME-TEST-PLAN.md) is a concrete proposal for completing those missing systems. Unresolved rules and scope choices remain decisions, not implicit implementation approvals.

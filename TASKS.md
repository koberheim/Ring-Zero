# RING ZERO — Tasks

| Marker | Status | Meaning |
|---|---|---|
| ⚪ | Not started | Defined, not yet assigned or begun |
| 🔵 | Assigned | Brief written and handed to an agent |
| 🟡 | In progress | Agent is actively working |
| 🟠 | In review | Delivered, Astra is verifying |
| 🟢 | Done | Verified and integrated |
| 🔴 | Blocked | Cannot proceed — say why and what unblocks it |
| ⚫ | Cancelled | Dropped — say why |

**Updated:** 2026-09-08. Feature completion authorized; baseline30suites passes. T-062/T-063/T-064 audits complete; T-065/T-066/T-067 implement remaining features and production-oriented16:9 UI. T-068 final integration follows owner freeze. See docs/contracts/feature-completion-2026-09-08.md. **Art direction is now decided (D-120, resolving D-030)** — see the art production section below (T-072+), plus two rule/UI changes it raised: D-121 (wedge destruction destroys occupants, salvage refund) and D-122 (Alt tactical overlay).

## Art production — 2026-09-08

D-120 settles final art direction; `docs/art-direction-style-guide.md` is the decided guide and `docs/art-asset-pipeline.md` is the production process, budget (~35-45 generated source images) and asset manifest. Two decisions raised by the same pass need implementing before the art can be honest about the rules: D-121 and D-122.

Work is deliberately ordered as a vertical slice first (pipeline stage 0-1) so the pipeline is proven on ~5 assets before the rest of the budget is spent.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-072 | D-121 wedge destruction destroys occupants, with salvage refund | Terra | ⚪ Not started | Rule change with real balance consequences. On wedge HP reaching 0, clear all occupants (5 weapons, Armor Plating, Repair Node, and the 3 terrain items) and credit a salvage fraction of their energy cost. New first-pass tuning value under D-033. Note `WeaponRules._step_owned` currently fires weapons with no wedge-HP check, so weapons on broken wedges fire at full effect today — that is the behaviour being removed. Needs the T-023 baseline treated carefully (state shape and combat behaviour both change) and a retune pass afterwards; breaches now compound. |
| T-073 | D-122 Alt-held tactical overlay | Luna | ⚪ Not started | Hold Alt to reveal one tactical layer: wedge HP bars above each wedge, terrain effect zones with exact edges, tractor lane direction arrows, weapon range arcs. Must respect D-119's strategic-zoom suppression and D-115's non-colour-only rule. This is the standing pattern for every future invisible rule — it replaces any argument for permanent world markings. |
| T-074 | Thin band + spoke ring geometry, with depth | Luna | ⚪ Not started | Replaces the current wide opaque wedge plates with the decided geometry: thin structural band at each ring's outer radius, radial truss spokes on wedge boundary lines shared between adjacent wedges, mostly-open annulus. Destroyed wedge removes its band segment only; a shared spoke goes only when both adjacent wedges are destroyed. Spokes must render as visibly open truss so free angular movement stays honest. Per D-123 the bands and spokes carry **real depth** — beams and girders with visible side faces, procedural so no image cost; the thickness is also where buckling/shearing damage reads live. This is the single highest-leverage visual change and what fixes T-049's flat grey strategic view. Depends on T-080. **Carries two open watch items from T-078/D-126:** re-test the standard machine's strategic-zoom/crowd legibility with real pathing-driven spacing (not the vertical slice's deliberately adversarial overlap test) once machines actually render through this system, and check whether the working-band's tiling seam mismatch becomes visible under the real angular-repeat sampling. |
| T-080 | D-123 camera tilt to 20° from vertical | Sol | ⚪ Not started | Apply the tilt as a Y-scale on the world transform, so rendering and picking stay consistent (input already routes through `get_canvas_transform().affine_inverse()`, so ability aiming and slot selection should need no math changes — verify, don't assume). Ground plane only: the star and corona are spheres and must stay circular. Draw order becomes painter's algorithm by screen Y. Sprites anchor at their ground point so footprints sit on true slot positions. World-space text (building labels, D-122 Alt HP bars) must not inherit the squash or height offset. Orientation stays fixed — no map rotation. Do this before T-078 generates any art, since the generation camera angle depends on it. |
| T-075 | Lighting, void atmosphere and ring-tier identity | Luna | ⚪ Not started | Star key light on inward faces; local industrial lamps on outward faces; corona bleeding outward through the gaps and tapering to dark starfield; ring-index material/temperature gradient (inner hot/scorched → outer cold/pale); state colouring at strategic zoom. All procedural/shader, no image budget. Local lights double as the continuous damage read (steady → flicker/amber → dark). |
| T-076 | Reactive star and skin pool | Luna | ⚪ Not started | Corona responds to game state (power draw pulse, brownout guttering, solar-cast flare) and draws from a skin pool (red giant/yellow/white and variations), randomized on a fresh run and persistent within a continuous run. Extends T-049's existing sun shader. Every other colour in the game must stay legible against every skin — worth an explicit check. |
| T-077 | Per-weapon procedural fire VFX (closes T-056) | Luna | ⚪ Not started | Distinct firing language per weapon, drawn procedurally: flak cone burst, mass driver slug + recoil flash, lance blooming beam, EMP expanding pulse ring, point defense tracer stream. Plus restrained kill effects and loud wedge-breach / ring-collapse effects. Supersedes the queued T-056 with a decided approach; costs no image budget. |
| T-078 | Art pipeline stage 0-1: anchor and vertical slice | Kevin (generation), Astra (review) | 🟢 Done | **Anchor (D-125):** `assets/art/anchor/anchor_approved.png`, approved after a two-round camera-angle correction (see D-124/D-125). **Five-asset slice generated, normalised and reviewed (D-126):** band strip, decal sheet, mount, Mass Driver head, standard machine — all in `assets/art/{bands,decals,buildings,machines}/`. Full honest report at `docs/reviews/T-078-vertical-slice.md`, evidence captures at `docs/reviews/artifacts/T-078-*.png`. **Verdict (D-126): pipeline mechanics accepted**, not a full production pass — the report correctly declined to fudge one. Reusable tooling proven: `scripts/art/normalize_asset.py` + 4 regression tests, existing art-preview suite still 59/59. Three issues found and accepted with explicit disposition rather than silently waved through: (1) standard machine ~2px and illegible at strategic zoom, dissolves under dense crowd overlap — deferred, the crowd test used deliberately adversarial density and the "mass at range" scale model may make this partly by design; re-test once T-074/T-075 wire up the real renderer with actual pathing-driven spacing; (2) working-band tiling seam has a measurable but not-yet-visible mismatch — accepted as-is, revisit only if T-074's real angular-repeat renderer exposes it; (3) normalize script's illumination suppression is bounded, not true flat-albedo recovery — accepted as a known limitation. Mount/head/machine rotation check passed cleanly at all 12 bearings with no lean, and the yellow-star check was strong. Unblocks T-079. |
| T-079 | Art pipeline stages 2-4: full asset pass | Kevin (generation), Astra (review) | ⚪ Not started | Remaining band tiers and damage sheet, the other 12 building heads, then 5 elites and the Assembler. Every asset through the same normalisation steps and the same four-point review gate (close zoom, strategic zoom, against every star skin, and in a crowd for machines). Unblocked by T-078 (D-126) — proceed using the proven pipeline as-is; do not re-fix the band seam or machine legibility pre-emptively, both are open watch items against T-074/T-075's real renderer, not re-opened generation tasks. |

**Ordering note (D-123):** T-080 (camera tilt) comes first. Objects are generated at 20° to match the camera, so the angle must be settled and verified in engine before T-078 generates anything. T-074's ring depth also assumes the tilt exists — depth is invisible at true top-down.

**Art production note:** the sprite work depends on engineering that does not exist yet — sprite-based building rendering (shared mount + head composite) and a MultiMesh sprite path for machines with elite/boss variants. Those land inside T-074/T-075 rather than as separate rows, but they are the real prerequisites for T-079 being usable.

## Phase 9 — remaining elites and Assembler boss

Per §§10.2-10.3 and D-019, this phase adds Transfer, Foundry, Sapper, and Breacher (Tunneler is already built, Phase 6/7 era) plus the Assembler boss. Kevin asked to continue straight into this phase, with balance/numeric tuning explicitly deferred to his own playtesting (per D-033).

**Rule briefing approved 2026-09-07:** Kevin approved D-106 (Foundry, Option A: pure stat-variant, no new engine mechanic), D-107 (Transfer, Option A: one-time ring-skip hop then standard-machine behavior), D-108 (Sapper, Option A+C: attacks a new ring-wide relay-hp pool through normal wall/funneling rules, loss browns out the ring rather than collapsing it, plus a new Rebuild Relay purchase — this resolves D-104's deferred relay-killability item), D-109 (Breacher, Option A: dedicated wall-seeking routing, full unpenalized wall damage), D-110 (Assembler, Option A+C: fixed-interval boss spawn, own permanent non-decaying growth from what it personally destroys) — all as recommended, in one bundled pass. All numeric values are first-pass under D-033, tuned later by Kevin's own play.

Recommended build order (simplest/least-coupled first): Foundry (no new engine mechanic) → Transfer (one-time hop, reuses standard-machine code after) → Sapper (new relay-hp pool + Rebuild Relay purchase) → Breacher (new per-machine routing) → Assembler (largest, benefits from patterns the others establish).

**T-057 through T-061 are all done** (Foundry, Transfer, Sapper, Breacher, Assembler). Phase 9 is complete.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-057 | D-106 Foundry (Option A: pure stat-variant) | Terra | 🟢 Done | New `foundry_rules.gd` mirrors `TunnelerRules`' scheduled-arrival shape (`foundry.first_arrival_seconds`/`arrival_interval_seconds`) but produces an ordinary standard-machine descriptor — same `stats_at()` growth curve as normal machines, multiplied by `foundry.hp_multiplier`/`damage_multiplier`/`speed_multiplier` (first-pass: 20x HP, 3x damage, 0.4x speed), same perimeter-band spawn position/bearing-cycle formula as `MachineSpawnRules.spawn_descriptor`. Admitted machines carry `kind: &"foundry"` but otherwise use `_advance_machine` and ordinary combat completely unchanged — confirmed zero new engine mechanic needed, exactly as D-106 predicted. `LiveSimulation.create()` gained a 4th optional `include_foundry` parameter (existing call sites unaffected); `_admission_plan` extended from a two-way (normal/Tunneler) to a three-way merge with explicit exact-tie priority Tunneler > Foundry > normal; `_valid_machine_source` gained a Foundry branch (kind present, but validated as an ordinary machine position, not Tunneler shape) with the same size-based fast-path Tunneler validation already had. New `skipped_foundry_arrivals` counter parallels the existing Tunneler one. 50 new checks in `test_foundry_rules.gd`, 11 new integration checks in `test_live_simulation.gd` (admission timing, kind tag, HP multiplier, ordinary movement after the arrival-boundary tick, capacity skip counter, exact-tie priority against Tunneler). Full 26-suite run passes; T-023 baseline confirmed unaffected (`foundry_enabled` defaults false, cost fixture never turns it on). |
| T-058 | D-107 Transfer (Option A: one-time ring-skip hop) | Terra | 🟢 Done | New `transfer_rules.gd` mirrors the same scheduled-arrival shape (`transfer.first_arrival_seconds`/`arrival_interval_seconds`) as a plain standard-machine descriptor with no stat multipliers — the elite identity is entirely the hop, implemented in `LiveSimulation`, not raw stats. Engineering finding worth recording: the "land behind the ring it skipped" requirement conflicts with the navigation model's core invariant that a cell sealed by an intact ring wall is never a graph node (nothing can normally be there) — landing there is a genuine, bounded exception, not a simple position write. Implemented as: inside `_advance_machine`, an un-hopped Transfer that reaches `route.goal_cell == cell` with a non-core target intercepts the attack, teleports to `route.target_cell` (radial 0, angular 0.5) with no damage either way, and sets `hopped = true` / `hop_cell` to that cell. While `position.ring == hop_cell.x` (still standing in the skipped band), a new `_advance_transfer`/`_advance_hopped_transfer` pair manually attacks whatever is one ring further in (or the core, if it hopped past ring 1) using the same manual target-dict pattern Tunneler's `surface_attack` already established — bypassing `route_for` entirely, since that band is legitimately absent from the shared graph. Once that inner wedge breaks, its position is moved into the now-genuinely-open inner band and every later tick falls through to ordinary `_advance_machine`/`route_for` — fully standard from then on, exactly per D-107. `_valid_machine_source` gained a Transfer branch validating the phantom-band position positionally (bypassing `navigation.has_cell`) instead of rejecting it; `_terrain_candidate_errors` gained the matching skip. `_admission_plan` extended to a four-way merge, exact-tie priority Tunneler > Foundry > Transfer > normal. The two per-tick Transfer fields (`hopped`, `hop_cell`) were added to the shared generic-copy field list; the tunneler-required-fields check was kept on its own separate constant so real Tunnelers aren't broken by the extension (a fixture-only bug in the first test pass — a hand-built 6-key test payload for Transfer accidentally matched the "normal machine descriptor" size threshold and silently lost its kind tag — was caught before merge). 49 new checks in `test_transfer_rules.gd`, 20 new integration checks in `test_live_simulation.gd` (single-ring core-hop edge case, two-ring hop-then-grind-then-resume-standard sequence with explicit checks that the skipped ring's own wedge is never damaged across the machine's whole life, capacity skip counter, exact-tie priority against Foundry and normal). Full 27-suite run passes; T-023 baseline confirmed unaffected via `--cost-review` (0 digest mismatches; `transfer_enabled` defaults false and the cost fixture never turns it on). |
| T-059 | D-108 Sapper (Option A + C: relay-hp target, brownout/rebuild) | Terra | 🟢 Done | New `sapper_rules.gd` mirrors the same scheduled-arrival shape, plain standard-machine stats, no multipliers. Sapper reuses `_advance_machine` completely unchanged (D-108: "paths and interacts with walls/wedges exactly like a standard machine") — the only new code is in `_attack_surface`: when a Sapper is attacking a bare wedge (`target_kind == &"wedge"`), its damage now drains that ring's new `relay_hp` pool instead of the wedge's own HP (the wedge itself is never touched by a Sapper); a standing wall is still damaged completely normally first (wall redundancy stays meaningful, per the recommendation's "what we get"). Every non-collapsed ring record gained sibling `relay_hp`/`relay_max_hp` fields (separate from any wedge's HP, set by `_empty_ring`, validated by `validate_state`, erased alongside `relay` on collapse). Reaching zero relay HP browns out the ring without collapsing it: `PowerRules.chain_boundary` now also breaks the outward power chain at a ring with `relay_hp <= 0` (previously only `collapsed`), so both that ring's own output and every ring beyond it drop to D-023's existing `brownout_fraction` — wedges/walls/occupants remain fully intact, matching Option C exactly. New `Rebuild Relay` purchase (`RingPurchaseRules.quote_rebuild_relay`/`rebuild_relay`, wired through `LiveSimulation`) restores `relay_hp` to full for a flat `economy.rebuild_relay_cost` — this is the concrete resolution of D-104's deferred "independent relay targeting/destruction" follow-up. `_admission_plan` extended to a five-way merge, exact-tie priority Tunneler > Foundry > Transfer > Sapper > normal; `_valid_machine_source` gained a Sapper branch identical in shape to Foundry's (kind tag, ordinary position, no tunneler-only fields). New `events.relays_lost` array reports rings that browned out that tick, mirroring the existing `broken_wedges`/`collapsed_rings` event pattern. 99 new checks (50 in `test_sapper_rules.gd`, 49 integration checks in `test_live_simulation.gd`: relay-drain vs wall-damage distinction — the wall test needed the whole ring sealed, not just one wedge, since funneling otherwise routes a Sapper around a single walled wedge to an exposed one exactly like a standard machine — brownout event/chain-boundary/power-output math, Rebuild Relay quote/purchase/rejection paths, capacity skip counter, exact-tie priority). Fixed along the way: ~13 test/capture files that manually simulated ring collapse via `ring.relay = {}` (bypassing the real collapse code path) needed a matching `erase("relay_hp"/"relay_max_hp")` to satisfy the new collapsed-ring invariant — caught immediately by `validate_state` rejecting the resulting malformed fixtures. Full 28-suite run passes; T-023 baseline re-recorded (every non-collapsed ring's state shape gained two fields — confirmed a pure shape change via `--cost-review` before recording, zero non-digest mismatches) and reran clean (785/0). |
| T-060 | D-109 Breacher (Option A: wall-seeking routing, full damage) | Terra | 🟢 Done | The genuinely new engineering piece D-109 flagged: `WallNavigation` already computed a `_walls` route field internally (shortest path to the nearest standing wall, ignoring detour cost) but only ever consulted it as a last resort when a cell's `_exposed` field had no reachable detour at all. Added `WallNavigation.wall_route_for(cell)`, which uses that same precomputed field *unconditionally* — falling back to the ordinary `route_for` only when no wall exists anywhere in the reachable graph (nothing to smash, so it behaves like a standard machine). `_advance_machine` dispatches to it for `kind == &"breacher"` with a single ternary at the route-lookup site — every other movement/waypoint/shadow-speed mechanism is reused completely unchanged, the same "zero new engine mechanic beyond the one deliberate piece" pattern as the other elites. `_attack_surface`'s wall branch skips `standard_machine.wall_damage_multiplier` (the 25% sealed-only rate) for Breacher, applying full damage — wall-breaking is its specialty, not a last resort. New `breacher_rules.gd` mirrors the same scheduled-arrival shape as Sapper/Transfer, plain standard-machine stats, no multipliers. `_admission_plan` extended to a six-way merge, exact-tie priority Tunneler > Foundry > Transfer > Sapper > Breacher > normal; `_valid_machine_source` gained a Breacher branch identical in shape to Foundry/Sapper's. 99 new checks (49 in `test_breacher_rules.gd`; 2 direct `WallNavigation` unit checks confirming `wall_route_for` matches the ordinary route when no wall exists, and that it targets an adjacent wall even with an open detour available; the rest integration checks in `test_live_simulation.gd` proving the routing inversion directly — a same-position standard machine funnels away from a single walled wedge while a Breacher targets it immediately for full, undiscounted damage — plus the no-wall-anywhere fallback, capacity skip counter, and exact-tie priority). Full 29-suite run passes; T-023 baseline unaffected (no new state shape this time — confirmed via `--cost-review`, 785/0). |
| T-061 | D-110 Assembler (Option A + C: interval spawn, own permanent growth) | Terra | 🟢 Done | **Phase 9's final item.** Fixed-interval boss spawn via new `assembler_rules.gd` (own `assembler.first_arrival_seconds`/`interval_seconds`, unrelated to run progress, per Option A), with boss-scale stat multipliers (first-pass: 40x HP, 4x damage, 0.3x speed) — reuses `MachineSpawnRules.stats_at()`'s growth curve like Foundry. "Ignores walls" (D-110's other trait) is implemented as ignoring walls *specifically*, not wedges: a third `WallNavigation` route field, `_ignore_walls` (goals are every open cell adjacent to an intact inward wedge, walled or not — a superset of `_exposed ∪ _walls`'s goal sets), backs a new `assembler_route_for`, dispatched from `_advance_machine` the same one-ternary way as Breacher's `wall_route_for`. A walled wedge is exactly as valid a target as a bare one and Assembler never resolves to `target_kind == &"wall"` — the wall is simply never examined — but it still grinds down and eventually breaks the wedge itself completely normally, through the same unmodified wedge-damage code every other machine uses. Its own permanent, non-decaying growth (Option C, a second and separate mechanism from D-021's global assimilation) is a new persistent `growth_stacks` int on the machine: +1 for each wedge it personally breaks via `_grant_assembler_growth`, plus the same occupant/wall count the existing ring-collapse sweep already computes if that break also collapses the ring (reusing that exact count rather than re-deriving it). Each stack grants an immediate flat HP bonus (`assembler.growth_hp_per_stack`) and permanently multiplies its own damage (`_assembler_growth_multiplier`, stacking alongside — not replacing — `_assimilation_multiplier` in `_attack_surface`'s damage line). 92 new checks (42 in `test_assembler_rules.gd`; 2 direct `WallNavigation` unit checks for `assembler_route_for`, both with and without a wall present, both funneled and fully sealed; the rest integration checks in `test_live_simulation.gd`: wall-immunity contrast against a same-position standard machine, the collapse-triggered growth math, and the persisted damage/HP bonus on a later tick). Full 30-suite run passes; T-023 baseline unaffected (`assembler_enabled` defaults false, cost fixture never turns it on; confirmed 785/0 clean). **Phase 9 is now complete: all five elites/boss (Tunneler pre-dates this phase) are implemented and tested.** |

**T-057 note:** required a manual Godot editor rescan (`--headless --editor --quit-after 1`) to register the new `FoundryRules` global class in `.godot/global_script_class_cache.cfg` — a fresh `class_name` script isn't picked up by a plain `--script` headless run until the project's class cache is refreshed once. Worth remembering for any future new `class_name` file in this project (repeated for `TransferRules`/`SapperRules`/`BreacherRules`/`AssemblerRules` in T-058 through T-061).

**T-061 test-design notes:** (1) a hand-built fixture for the growth test forgot that `create_default_testing_state`'s starter Flak occupant existed on an untouched wedge of the same ring — the ring-collapse sweep counts occupants across *all 12* wedges regardless of which ones broke, so that stray Flak inflated the expected growth-stack count by one until the fixture explicitly cleared every wedge's occupants first. (2) the tick immediately after Assembler's own attack collapses a ring is spent *moving* into the newly-opened space, not attacking — `_advance_machine` re-routes fresh next tick since the ring it just broke through is no longer a valid attack goal at all (fully open now), so a test asserting "next tick already deals boosted core damage" is wrong; it needs to step until arrival, then check the first tick that actually reduces `core_hp`. Both were caught by `--cost-review`-style first-principles checking (computing the expected value independently) rather than assuming the implementation was right when a test failed.

## Phase 1 — Foundation and readable grid

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-001 | Read the spec and create the three planning documents | Astra | 🟢 Done | Read all 18 sections. Drafted phases through the slice, phase-one tasks, and decision inventory. Checked references and scope on 09-06. Plan approval was subsequently received. |
| T-002 | Define the shared foundation contract | Astra | 🟢 Done | D-004 and D-006-D-009 approved. Contract at docs/contracts/phase-1-foundation.md checked against approved recommendations. |
| T-003 | Create the Godot project and polar grid | Sol | 🟢 Done | Astra reviewed source, contract, runner, logs, and report. 1,206 checks passed; Godot import and launch exit 0. Accepted 09-06. |
| T-004 | Show and inspect the procedural grid | Luna | 🟢 Done | Astra accepted source, rendered views, and input checks including ring 12. 6,668 headless / 6,674 graphical checks passed. |
| T-005 | Review and integrate the foundation | Astra | 🟢 Done | Technical review passed; Kevin accepted D-038 Option A on 09-06. Phase 1 closed. |

### T-002 — Done condition

Record exact file paths and names; ring and wedge numbering; core representation; legal cell boundaries; any within-cell polar position; conversion and selection function signatures; and the data passed from the grid to presentation. State how ring count is configured without a hard grid ceiling. Define who writes each file. Include foundation validation examples. These are contracts, not feature implementations.

**Review:** Astra checks every field against Kevin's recorded answers and the spec before any agent receives work.

### T-003 — Done condition

Godot project opens with the agreed runtime settings. The grid supports the agreed core, 12 bearings, configurable rings, neighbors, polar/world conversion for display, and selection conversion. World coordinates are not stored as authoritative gameplay positions. No gameplay features are added.

**Review:** Run focused geometry checks for north/east, wedge wrapping, adjacent rings, core and boundary selection, round-trip conversion, and an inspection grid through ring 12. Record the actual commands and results when implemented.

### T-004 — Done condition

Generate visible wedge geometry from T-003's data. Add agreed style-agnostic cell labels or equivalent inspection feedback, fixed north-up pan/zoom, and cell selection. The approved three-ring setup and ring-12 inspection remain selectable. Presentation consumes the grid rather than keeping a competing map.

**Review:** Inspect the running scene at near and far zoom, pan away from the core, and verify cursor selection at the seam and boundaries. Kevin reviews projection and placeholder readability. No final art or audio choices are implied.

### T-005 — Done condition

Record foundation check results and Kevin's presentation feedback. Send deviations to the owning agent. Integrate only reviewed deliveries. Update all three logs and define phase-two tasks only when phase one is accepted and relevant decisions have cleared.

## Session record

2026-09-06: Planning-only kickoff completed. The repository initially contained only the design spec. No feature code, agent briefs, agent assignments, or implementation tests were created. The design spec was not edited.

2026-09-06 approval follow-up: Kevin approved the plan and foundation recommendations. T-002 completed; T-003 authorized for Sol. D-025 still blocks Luna; no other approvals inferred.

2026-09-06 further answers: D-005 Option A excludes recovery/power/abilities from the slice. D-006-D-008 confirmed Option A. D-025 foundation controls approved; T-004 now waits only on the engine handoff and its brief.

2026-09-06 engine handoff: Astra accepted T-003 after reviewing 1,206 passing checks and runtime evidence. Luna assigned T-004. Process-local cache redirection removed editor cache errors; certificate-store warning is environmental. No machine-load or human readability verdict yet.

2026-09-06 presentation handoff: Astra accepted T-004 after a focused ring-12 click-test correction. Three actual 1280x900 captures reviewed. Main scene is runnable in project.godot. T-005 awaits Kevin under D-038. Phase 2 has not begun; its gameplay decisions remain pending.

## Phase 2 - balance data and live-loop preparation

D-010-D-015 are approved. T-007 supplies the independent data foundation. D-044/D-045 settle startup/relay placement and expansion eligibility; D-025/D-047 build controls and aiming are approved. D-016 routing is approved and D-017 pressure is approved for testing only; final crowd capacity remains open. D-039 supplies the approved 7-wedge threshold and menu-pause exception.

2026-09-06: Kevin accepted D-038 Option A; T-005 and Phase 1 complete. All completed Phase 1 tasks remain in this history.

2026-09-06: D-039 both rule changes approved and synchronized in the plan. No gameplay implementation exists yet to modify.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-006 | Define the approved balance-data contract | Astra | 🟢 Done | docs/contracts/T-007-balance-data.md checked against D-010-D-015 and D-040/D-041. |
| T-007 | Implement editable balance profile and validation | Terra | 🟢 Done | Astra accepted data, loader, docs, and focused checks: 131 passed; Godot import exit 0. No gameplay integration. |
| T-008 | Define purchase, placement, and startup handoff | Astra | 🟢 Done | docs/contracts/T-008-purchases.md records approved startup/whole-ring rules and atomic data transitions; physical slot geometry stays in D-047. Consumer implementation unassigned. |
| T-009 | Define combat and build-input handoffs | Astra | 🟢 Done | T-010 and T-011 contracts define shared rules and UI handoff; approved D-025/D-047. Movement/spawn integration remains gated on D-016/D-017. |

T-007 done condition: approved values exist in one editable profile; loading/validation/isolated overrides work; invalid profiles fail clearly; focused Godot checks pass; Astra reviews before acceptance. T-008/T-009 are contract tasks, not implementation assignments.

2026-09-06: D-010-D-015 approved; D-040 fixes ring package price; D-041 defers power behavior. Terra assigned only the independent data foundation. Final starting state remains open under D-042.

2026-09-06 data handoff: T-007 accepted with 131 passing checks. T-008 contract prepared and checked against approved rules. The running scene remains the Phase 1 inspector; no purchases or combat have been integrated. Later approvals cleared D-047/D-025; movement/spawn decisions remain visible under D-016/D-017.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-010 | Implement purchases, placement, and automatic weapon rules | Terra | 🟢 Done | Astra accepted source and 242 passing focused checks. Cadence and affordable-quote findings corrected. No loop/spawning integration. |
| T-011 | Integrate startup and build controls into the playable view | Luna | 🟢 Done | Final focused suite49 passed; prior rendered60 and inspector6668 passed. Four PNGs reviewed; Kevin accepted stage view, slots revisable (D-050). |

2026-09-06: D-025/D-047 Option A approved. All armed buildings select targets and fire automatically. Player-targeted solar abilities remain deferred. No movement/spawn settings inferred.

2026-09-06 rule handoff: T-010 accepted (141 balance, 45 purchases/placement, 56 weapon checks). Luna assigned T-011. All armed buildings use automatic rules; solar attacks remain separate/deferred.

2026-09-06 pressure answers: D-016 approved; D-017 profile approved for testing only. Final gameplay targets hundreds/thousands of concurrent enemies. Next engine work must measure crowd scale and retain editable pressure data; D-007 hard-cap follow-up remains open. No low-density prototype result is a final performance claim.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-012 | Implement clock/entity storage and measure crowd costs | Sol | 🟢 Done | Astra accepted tests and 500/1,000/5,000 measurements; callback pause corrected. Targeting cost needs T-013; no cap chosen. |

T-012 done condition: generic pool and clock meet contract, focused checks pass, bounded measurements are reported with sample counts/limits, and Astra reviews before acceptance. Measurements are not a full-game FPS claim.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-013 | Remove repeated targeting work and verify unchanged behavior | Terra | 🟢 Done | Astra reviewed source/reference tests and reran 219 passing checks. Same benchmark medians 3.119/6.250/35.246 ms at 500/1,000/5,000 targets. See docs/reviews/T-013-acceptance.md; no final cap chosen. |

2026-09-06: Kevin accepted the build view for this stage and may revise slot placement later. T-011/T-012 accepted. Headless ready-volley cost exceeded one 60 Hz tick at1,000+; Terra assigned corrective optimization without changing rules or selecting a cap.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-014 | Add approved editable testing pressure data | Terra | 🟢 Done | Astra reviewed data/schema/docs and reran 271 balance, 45 building, and 219 weapon checks; all passed. No growth formula or live behavior inferred. |

2026-09-06 continuation: Kevin requested continued work and clear briefings for decisions. Escalation semantics and crowd movement are briefed in D-053/D-054 while independent pressure data proceeds.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-015 | Compute shared routes over explicit polar connections | Sol | 🟢 Done | Astra reviewed implementation/reference tests and reran PASS exit 0. 1,201-cell rebuild median 20.000 ms; three-query sweep 0.799 ms. No implicit gameplay path costs or wall rules. |

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-016 | Implement approved test spawn schedule and new-machine stats | Terra | 🟢 Done | Astra reviewed source and independently reran 147 passing checks; docs/reviews/T-016-acceptance.md. |

Kevin requested continued work through verification until a user review/decision point is reached. Do not stop merely because an internal utility is complete while other authorized work can proceed.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-017 | Connect spawning, radial pressure, ring/core damage, kills and purchases | Terra | 🟢 Done | Astra accepted source and reran 820 passing checks; docs/reviews/T-017-acceptance.md. Wall-free Phase2 loop. |

D-020 outer-ring survival, D-058 occupied-band purchase rejection, and D-059 editable1,000-enemy trial are approved. No remaining user gate for T-016/T-017; implementation/review continues.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-018 | Integrate and render the reviewed live test | Luna | 🟢 Done | Astra accepted source, independently reran66 live/49 build checks, inspected3 final captures and reviewed corrected1000-machine rendering. Kevin accepted D-064. |

Historical T-018 performance correction: the initial rendered1000-machine trial measured37.698ms median frame interval. Luna corrected marker batching under D-063, reaching16.655ms median with VSync enabled. Astra accepted the correction and Kevin subsequently accepted D-064. This stationary-contact measurement does not establish wall-routing performance.

D-064 accepted by Kevin. The next concrete decision point is D-065/D-066 wall geometry and sealed-layout behavior. Do not assign wall implementation against unapproved recommendations.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-019 | Implement approved outer-edge wall placement and validation | Terra | 🟢 Done | Astra source review and473 consumer/focused checks passed; runtime integration follows. |

Kevin approved D-065 Option A and supplied D-066 Option C: reduced normal-enemy wall damage only when the whole perimeter is walled. D-067/D-068 brief the remaining numeric/closure choices. T-019 proceeds; no live wall button until routing/combat/collapse consumers are integrated.

D-06725% testing wall damage approved. D-068 was subsequently approved: no exposed surface reachable; see current integration tasks below.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-020 | Implement constant-speed polar segment motion | Sol | 🟢 Done | Astra source review and independent PASS exit0; docs/reviews/T-020-acceptance.md. |
| T-021 | Integrate shared wall routes and conditional reduced wall attacks | Terra | 🟢 Done | Gameplay accepted; 1091 independent checks and 508 consumer checks pass. Rendered performance remains unresolved; docs/reviews/T-021-acceptance.md. |

T-019 accepted after97 wall/45 building/219 weapon/112 live checks. D-068 reachable-surface closure approved. No user decision currently blocks wall implementation; continue through runtime and visible integration to review.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-022 | Integrate wall controls, edge lines and funnel feedback | Luna | 🟢 Done | Independent199 control checks pass;4captures reviewed. D-073 stage review accepted. Angular frame-time shortfall diagnosed as near-zero simulation margin, not a defect; Kevin accepted current performance 2026-09-07. docs/reviews/T-022-astra-review.md. |

T-020 accepted independently. T-021 shared routes and conditional wall attacks assigned; T-022 presentation contract prepared. Previous impossible embedded-enemy collapse fixtures will receive an open outer-wedge approach while preserving outer-survival assertions.

T-021 gameplay accepted; T-022 active. Sol is performing a bounded read-only review of per-machine costs while Luna implements presentation. No concurrent benchmark runs or source edits are authorized by that advisory review. Rendered angular fixtures may use a larger approved ring perimeter to keep every machine moving throughout the sampling window, with geometry and time limits explicitly reported.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-023 | Measure and reduce repeated live simulation work | Terra | 🟢 Done | Three measured corrections accepted;1558 independent focused/cost checks pass. docs/reviews/T-023-acceptance.md. Rendered performance still open. |

T-022 four wall captures pass initial Astra inspection;84 wall checks pass. Rendered1000 sealed frame50.113ms median and angular diagnostic136.599ms show accumulated simulation catch-up. Angular sample reached contact before120frames and is not accepted as continuous movement evidence. T-023 correction assigned; T-022 remains unfinished until corrected rendered verification.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-024 | Reduce repeated polar motion reconstruction | Sol | 🟢 Done | No reliable gain; original source/tests restored and independently verified. docs/reviews/T-024-acceptance.md. |

T-023 accepted and measurement window closed. T-024 Sol now owns exclusive motion measurement window; T-022 presentation remains frozen awaiting corrected rendered rerun. Timing anomalies and isolated diagnostic limits are preserved in T-023 reports.

T-024 found no reliable motion-specialization gain; original production helper restored. T-023 measured improvements remain. Luna has the exclusive final T-022 rendered rerun window. The upcoming human review will explicitly separate wall behavior/presentation from unresolved crowd-performance acceptance.

Current handoff: D-073 wall controls/feedback review ready for Kevin. Final1000 rendered sealed18.986ms median/30.840p90; angular diagnostic96.529/148.919ms with failed continuity. T-022 remains incomplete; crowd performance open. No agent test processes running. Further performance work remains authorized after this requested human review point; Tunneler needs D-018 briefing/approval.

Kevin accepted D-073 Option A. Wall controls and neutral feedback are accepted for this stage. T-022 remains in review solely for unresolved rendered performance; no final capacity or balance acceptance inferred. D-018 Tunneler rules remain the next gameplay decision.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-025 | Remove redundant private combat copies | Terra | 🟢 Done | Independent1423checks pass incl246exactdigests; measuredgain accepted. docs/reviews/T-025-acceptance.md. |

D-018 partial approval: Tunneler bypasses exactly one intact ring. Underground vulnerability and remaining implementation details are pending; no Tunneler implementation assigned. T-025 performance verification continues.

D-018 further approval: untargetable underground, vulnerable after surfacing, warning before emergence. Exact timing, warning presentation, fallback and editable testing values are not yet approved.

T-025 accepted. Luna has exclusive unchanged T-022 rendered rerun window; no other Godot measurements concurrently. D-018 depth and underground vulnerability approved, remaining detail briefing pending.

Current handoff: T-025 accepted and unchanged rendered reruns complete. Sealed1000 now16.650ms median/16.863p90; angular49.120/49.666ms with120/120continuous-angular frames. All1000 remain present. T-022 performance still in review against60Hz; stage presentation accepted D-073. D-018 depth/vulnerability approved. D-075/D-076/D-077 brief emergence, editable testing values and neutral warning; awaiting Kevin before Tunneler implementation. No agent measurement processes running.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-026 | Add Tunneler data and pure arrival/destination rules | Terra | 🟢 Done | Independent656checks and534consumer checks pass. docs/reviews/T-026-acceptance.md. |

T-027 runtime contract prepared at docs/contracts/T-027-tunneler-runtime.md; not assigned before T-026 acceptance and D-079 tie decision. Optional creation flag keeps current view unchanged until D-077 approval and presentation integration.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-027 | Integrate Tunneler lifecycle and mixed admissions | Terra | 🟢 Done | Independent 761 checks pass; 246 original digests retained. docs/reviews/T-027-acceptance.md. |

Current handoff: D-075/D-076 approvals recorded and T-026 accepted. Await D-079 cap tie (recommend eligibleTunnelerfirst) before runtime; D-077 warning/countdown/triangle stillpending. Existing wallscene remains unchanged.

D-077 and D-079 Option A approved. T-027 assigned; all current Tunneler gameplay/presentation choices cleared. Continue through live integration and visible verification to the next genuine review point.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-028 | Present Tunneler warning, emergence and inner damage | Luna | 🟢 Done | Independent 197 functional checks pass; D-080 stage accepted. Angular rendered performance diagnosed as near-zero simulation margin plus added draw cost; Kevin accepted current performance 2026-09-07. |

Current handoff: T-027 accepted after source review and 761 independent checks. Luna owns T-028 and the exclusive rendered measurement window. All current Tunneler choices are approved; continue to concrete visible stage review.

Current handoff 2026-09-07: T-027 accepted; T-028 functional source and captures reviewed, 197 independent checks pass. D-080 is the next Kevin review. Latest angular renders fail continuous-motion verification (101-104 ms diagnostic medians); all 1,000 retained, no acceptance inferred. No further measurements scheduled.

2026-09-07: Kevin accepted D-080 Option A. T-028 stage presentation is accepted; task remains in review solely for unresolved rendered performance. Kevin accepted D-024 Option A: persistent all-rings radial HUD direction is approved; no HUD implementation task is assigned yet, pending a concrete presentation brief.

2026-09-07: Astra reran the existing T-023 instrumented headless cost review unchanged (no source edits) to diagnose T-028's rendered regression. Angular (funneling) simulation alone costs 15,878.5 us median/16,414 us p90 per tick versus a 16,667 us budget; sealed costs 10,327 us median. The rendered failure is explained: near-zero angular margin plus T-028's added draw cost causes compounding catch-up, not a code defect. Kevin accepted current 1,000-machine testing performance; T-022 and T-028 are now Done. Final shipped crowd capacity remains a later, non-blocking D-007 follow-up.

2026-09-07: All Phase 3 tasks (T-019 through T-028) are Done. Kevin accepted D-081 Option A: Phase 3 complete, Phase 4 (ring-loss clarity and the D-024 HUD) is now open. No Phase 4 task is assigned yet; Astra is defining the first handoff(s).

## Phase 4 — ring-loss clarity and the D-024 HUD

Independent wedge HP, 7-of-12 collapse, no-refund destruction, and core defeat already exist from Phase 2/3 gameplay work (T-017/T-018) and are exercised by existing tests. The remaining Phase 4 deliverable is the D-024 persistent ring-status HUD.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-029 | Add the persistent radial ring-status HUD (D-024 Option A) | Luna | 🟢 Done | New `RingStatusHud` control in `src/presentation/ring_status_hud.gd`, wired into `live_view.gd`. 76 independent checks pass. Kevin accepted both captures for this testing stage 2026-09-07; 12-ring density is a known, accepted limitation, not a defect. |

T-029 done condition: fixed-screen radial overview shows every owned ring's 12 wedges, using color plus a non-color symbol (X for broken, dot for critical below 25% HP) so status is not color-only; a distinct marker shows a ring's surviving relay; collapsed rings render as a solid dark band. Left-click on a sector pans the camera to that ring/wedge without pausing or changing world-selection rules; clicking the center focuses the core. Auto-scales to whatever ring count is owned, so it stays exactly as specified through ring 12 without a fixed pixel budget being exceeded.

Astra's review: source reviewed; `tests/presentation/test_live_view.gd` gained 5 checks (broken-wedge status, click-to-focus math against a known sector, core-click, and collapse/relay status), all passing alongside the existing 66 (71 total). `tests/presentation/capture_ring_status_hud.gd` is a new isolated capture fixture (not attached to the playable scene) verifying a 3-ring mixed-status case and a 12-ring case built directly via `LiveSimulation.create(profile, 12)` (26 checks, all passing). Existing wall (84) and Tunneler (47) suites rerun unchanged and still pass; no gameplay/core file was touched.

Captures: [T-029-mixed-status.png](docs/reviews/artifacts/T-029-mixed-status.png) (3-ring case: one broken wedge, one collapsed ring, one critical wedge, one surviving relay — clearly legible) and [T-029-twelve-ring-readability.png](docs/reviews/artifacts/T-029-twelve-ring-readability.png) (12-ring case, per D-024's requested readability check). The 12-ring case is functionally correct but visually dense: at 12 bands the broken/critical marks are thin slivers with no visible per-wedge divider lines, matching the readability risk D-024 itself flagged for Option A ("A becomes dense").

**Resolution - 2026-09-07:** Kevin accepted both captures for this testing stage. The HUD reads well at the current 3-ring slice scale; 12-ring density is a known, accepted limitation to revisit later if/when the slice reaches that scale, not a defect. T-029 is Done. Phase 4's remaining deliverables (independent wedge HP, 7-of-12 collapse, no-refund destruction, core defeat) were already implemented and exercised in Phase 2/3 work, so Phase 4 has no further open implementation task at this time.

2026-09-07: Kevin accepted D-082 Option A: Phase 4 is complete. Kevin chose D-031 Option B: Phase 5 (evaluate the vertical slice) opens as a Kevin-only engineering review; broader/external playtesting is deferred until Kevin decides afterward whether it's warranted, and no participants are authorized. No numeric pass/fail thresholds exist yet for the five flagged risks (run sameness, death spiral, readability at scale, relay frustration, wedge scaling math). No Phase 5 task is assigned; Astra needs Kevin's direction on which concrete scenarios/measurements to prepare first.

## Phase 5 — engineering review evidence

Kevin approved a four-scenario scope (readability at scale, relay-status presentation, wedge scaling math, death-spiral behavior; run sameness out of scope for this engineering pass). Astra assembled [docs/reviews/phase-5-evidence.md](docs/reviews/phase-5-evidence.md) from existing fixtures/captures — no new implementation. While computing the wedge-scaling table, Astra found and fixed a real bug in T-029: the HUD's critical-threshold check compared live wedge HP against a flat base value instead of that ring's actual scaled max HP, making the critical mark harder to trigger than intended on every ring beyond ring 1. Corrected in `live_view.gd::_ring_status_records`; all 71 live-view checks (including the 5 HUD checks) still pass.

2026-09-07: Kevin accepted the Phase 5 evidence report (D-084). The vertical slice (Phases 1-5) is now evaluated and complete. No post-slice phase or task is assigned; Astra is awaiting Kevin's direction on priorities among the remaining open decisions (D-019, D-021-D-023, D-026-D-030, D-032-D-035, D-042, D-007 follow-up) before defining any next task.

## Post-slice audit and planning

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-030 | Audit Phase 5 state and plan the fully testable game | Astra | 🟢 Done | User-requested audit, read-only lane reviews, 17 passing suites, two reproduced gaps. docs/reviews/post-slice-audit.md and docs/FULL-GAME-TEST-PLAN.md. D-085 reviews proposed implementation scope. |

2026-09-07: No production edits in T-030. Audit A1/A4 need authoritative-HP correction and regressions; A2 needs integrated growing-world verification; A3 report units corrected with a dated annotation; A5 reproducibility and A6 full-run balance enter proposed Phase 6/7 work. Existing accepted tasks are not retroactively reopened. Future phase task IDs await authorization and bounded contracts.

## Phase 6 — reliable test baseline and repeatable sessions

Kevin approved D-085 Option A: "continue with Phase 6." Session/export/persistence scope (D-032) and tuning authority (D-033) are still open and gate part of this phase's deliverables; work not depending on them proceeds now.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-031 | Correct audit A1 and add A4 regressions | Luna | 🟢 Done | `live_view.gd::_ring_status_records` now reads each wedge's authoritative `max_hp` instead of recomputing from the profile. Added a ring-2 40/200 HP case, a nonstandard-max_hp case (100/500), and exact-25%-boundary cases. 75 live-view checks pass (71 prior + 4 new); wall (84) and Tunneler (47) suites rerun unchanged and still pass. |

T-031 done condition: HUD critical-threshold status matches each wedge's own `max_hp` field, not a value reconstructed from `health.wedge_base_hp`/`scaling.wedge_hp_ring_exponent`; regressions cover a case where those two would disagree (a nonstandard max_hp) and the exact 25% boundary. No gameplay/rule file changed — this is a presentation-layer read correction.

2026-09-07: T-031 accepted. Next Phase 6 items not gated by D-032/D-033: A5 reproducibility infrastructure (preserve baseline digests and provenance outside `.godot`, a one-command correctness runner, separate opt-in performance commands). Session lifecycle (new run/pause/retry), stable content IDs, and the private Windows export remain gated on D-032/D-033 per the plan's "Decision package first" note.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-032 | A5 reproducibility infrastructure | Sol | 🟢 Done | Relocated the T-023 baseline digest file from gitignored `.godot/` to tracked `tests/performance/baselines/t-023-sustained-cost-digests.bin` with a provenance README; `test_live_simulation.gd`'s path updated. Byte-identical relocation verified: `--cost-review` reruns all 245 digest comparisons unchanged (785 checks including wall/full-step, 0 failures). Added `scripts/run_tests.sh`, a one-command runner over every `tests/**/test_*.gd` suite (deliberately excludes `capture_*.gd`/`benchmark_*.gd`/`--cost-*` scripts, which stay opt-in). |
| T-033 | Session lifecycle: new run, retry, basic result summary | Luna | 🟢 Done | `live_view.gd` gained `_start_new_run()` (used by both initial startup and a new Retry button), a run-scoped kill counter, and a "Core lost. Survived Xs, Y kills." result summary. Found and fixed a real bug along the way (below). 80 live-view checks pass (75 prior + 5 new); full 17-suite run via `run_tests.sh` passes clean. |

T-032/T-033 review: while adding the Retry button next to the existing Resume button in the pause menu's `VBoxContainer`, discovered that Godot does not resolve that container's child layout on the same frame it becomes visible — a click issued before an intervening `await process_frame` can land on the wrong sibling. This is invisible to a real player (a rendered frame always separates "open the menu" from "click something in it") but broke `test_tunneler_view.gd`'s first-ever menu open (immediate resume click, no frame), which was clicking Retry instead of Resume and silently starting a fresh run mid-test. Fixed by adding the missing `await process_frame`, matching how `test_live_view.gd` already handled its first menu open. Separately, and more seriously: that failure's uncaught GDScript runtime error (an out-of-bounds array access) aborted `_run()` before it reached its own `quit()` call, leaving the headless Godot process running indefinitely instead of exiting nonzero — three such orphaned processes (one over 12 hours old) were found and killed during this session. `scripts/run_tests.sh` now wraps every suite in `timeout -k 10 90s`, so a future crash-before-quit reports as a timed-out FAIL instead of hanging the runner or leaking a process. See the script's inline comment for the mechanism.

2026-09-07: Kevin approved D-032 Option A (editor-only, restart-from-beginning): no mid-run save/resume, no standalone export for now. This keeps the remaining Phase 6 content-ID/command-interface work minimal and defers the private Windows export to Phase 11/13.

2026-09-07: Kevin approved D-033 Option B: "Codex or Claude will perform first pass tuning and then gameplay testing will adjust." Numeric tuning values (rates, costs, HP, timings, ranges, thresholds) for already-rule-approved systems no longer need a pre-implementation parameter sheet; an implementing agent picks reasonable first-pass values, records them plainly as provisional in the task notes and versioned balance data, and Kevin's gameplay testing adjusts them afterward. Rule/mechanic/scope/art/naming choices are not covered by this delegation and still come to Kevin first.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-034 | Phase 6 exit checks: repeated/mid-run retry, content-ID and commit-interface contract | Astra | 🟢 Done | Added tests proving Retry works mid-run (not just after loss) and across three consecutive cycles with no residual walls/machines/wedge-damage from the prior run (85 live-view checks, up from 80). Wrote [docs/contracts/phase-6-command-interface.md](docs/contracts/phase-6-command-interface.md) documenting the existing `StringName`-kind convention and `LiveSimulation.step()`'s stage-then-commit pattern as the interface future systems (Phase 7 repair/power/assimilation, Phase 8 abilities/status) must extend — a documentation contract, no source change. Run/profile/build identifiers are satisfied by the existing per-report prose convention (pinned Godot version, profile, fixture overrides in every review doc); a recorded identifier/command-log scheme is deferred until external testers or Phase 11 persistence actually need one. Full 17-suite run passes. |

2026-09-07: With T-031 through T-034 complete and D-085/D-032/D-033 all settled, every stated Phase 6 deliverable and exit check is met. Astra is asking Kevin to formally close Phase 6 (D-086) before opening Phase 7 (expansion, power, genuine recovery), which needs real rule decisions first (D-021 assimilation, D-022 retake/reclaim, D-023 relay/power, a D-027 repair/armor subset).

2026-09-07: Kevin accepted D-086. Phase 6 is complete.

## Phase 7 — expansion, power and genuine recovery

Rules approved 2026-09-07: D-021 (assimilation, Option A), D-022 (retaking, both Repair and Reclaim tiers), D-023 (power, Option B), and the D-027 Armor Plating/Repair Node subset. All numeric values are first-pass under D-033. Per FULL-GAME-TEST-PLAN.md, Phase 7 implements, in dependency order: (1) a growing world beyond the three-ring ceiling, (2) a destruction/restoration contract (intact/damaged/broken/collapsed/reclaimed states, exactly-once destruction events), (3) Armor Plating and Repair Node, (4) relay power, (5) assimilation.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-035 | D-022 Repair (Tier 1) and Reclaim (Tier 2) rules | Terra | 🟢 Done | `RingPurchaseRules` gained `quote_repair_wedge`/`repair_wedge` (heal a damaged, non-collapsed wedge for `10×ring×(missing/max)` energy, occupants untouched) and `quote_reclaim_ring`/`reclaim_ring` (rebuild a collapsed ring in place via the same whole-ring shape `purchase_next_ring` uses, at `economy.reclaim_discount` = 75% of normal cost). `LiveSimulation` gained matching `quote_repair`/`repair_wedge`/`quote_reclaim`/`reclaim_ring` wrappers, with reclaim's occupancy check mirroring `quote_expansion`'s. Added `economy.reclaim_discount` to the balance schema and `testing.json`. 71 new headless checks (13 in `test_building_rules.gd`, 10 in `test_live_simulation.gd`, plus the fixture/fixup checks); full 17-suite run passes (58/414 respectively, up from 45/404). No UI yet — this is the rule layer only, exercised headless. |

T-035 review: found and killed two more processes left running by earlier crashed diagnostic runs during this task's own debugging (a relay-slot-out-of-range fixture bug, then a `Dictionary` key-access-without-default bug in a test assertion) — same hang-before-quit pattern T-033 fixed for `run_tests.sh`, but these were run directly outside that wrapper. Direct one-off Godot invocations during development should still be checked for lingering processes afterward, not just suite runs through the wrapper.

Next: wire Repair/Reclaim into the playable view (build_mode buttons, click routing to a damaged wedge or collapsed ring) so D-022 is actually testable in play, not just headless — or continue the rule layer with Armor Plating/Repair Node (D-027 subset) and come back for UI once more of Phase 7's economy exists. Astra recommends finishing the remaining rule layers first (Armor/Repair Node next, matching the plan's dependency order) and wiring UI for the whole batch together, rather than three separate small UI passes.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-036 | D-027 subset: Armor Plating and Repair Node rules | Terra | 🟢 Done | `BuildingRules` gained `place_armor` (raises a wedge's `max_hp` and `hp` together by `structure.armor_plating_hp_bonus`, stacking up to `structure.armor_plating_max_stacks` per wedge) and `place_repair_node` (occupies a slot; healing is passive, not immediate). `LiveSimulation` gained a new per-tick step, `_apply_repair_nodes`: each `repair_node` occupant in a ring heals that ring's single most-damaged standing wedge (positive HP, below max — never a fully broken one) by `structure.repair_node_heal_fraction_per_second` of its max HP per second; multiple nodes on one ring compound on the same target. `validate_state` now accepts the two new occupant kinds and enforces the armor stack cap. Added `economy.armor_plating_cost`/`repair_node_cost` and `structure.armor_plating_hp_bonus`/`armor_plating_max_stacks`/`repair_node_heal_fraction_per_second` to the schema and `testing.json`. 25 new headless checks (7 in `test_building_rules.gd`, 8 in `test_live_simulation.gd`); full 17-suite run passes (65/422 respectively). |

**T-036 found a real, ship-would-have-broken regression, not just a test gap:** `WeaponRules._step_impl` iterated every wedge occupant and skipped only `&"relay"` before computing `profile.value("<kind>.range_ring_widths")` — the moment any ring held an `armor_plating` or `repair_node` occupant, that lookup returned `null` and `float(null)` crashed with "Nonexistent 'float' constructor" on every single tick thereafter (only caught because `_armor_repair_node_checks`' 600-tick sustained-healing loop actually ran combat resolution repeatedly; a placement-only test would have missed it). Fixed by switching from a deny-list (`kind == &"relay"`) to an allow-list (`kind not in [&"flak", &"mass_driver"]`), which won't need updating again as Phase 8 adds more non-combat occupant kinds (terrain). No existing weapon-rule test's expectations changed (357/357 still pass) — this is exactly the kind of defect the Phase 7 "extend the stage-then-commit pattern" contract exists to catch early, and confirms new occupant kinds need a pass through every place that enumerates `occupants` by kind, not just the placement rule itself.

Next: Repair/Reclaim and Armor/Repair Node rule layers are both done and headless-tested. Remaining Phase 7 rule work: D-023 power (the largest remaining piece — new balance fields, placement-time demand checks, brownout cascade) and D-021 assimilation (per-stack decay bookkeeping in `LiveSimulation.step`). UI wiring for everything built so far (Repair, Reclaim, Armor Plating, Repair Node) is still outstanding and best done as one batch once the rule layer is further along.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-037 | D-023 Option B power rules | Terra | 🟢 Done | New `PowerRules` class: `chain_boundary` (outermost unbroken non-collapsed run from ring 1 — see the noted simplification below), `ring_output` (`power.base_output / ring index`, ×`power.brownout_fraction` beyond a chain break), `ring_demand` (sum of placed `flak`/`mass_driver` `power_demand`), `can_afford` (placement-time only). `BuildingRules.place_weapon` now rejects a weapon the ring can't power. `WeaponRules._step_impl` spends each ring's power budget in fixed ring/wedge/slot order per tick; a weapon that doesn't fit goes fully inert (no fire) but still ages its own cooldown normally, so "powered" status only changes when occupants change, never as a side effect of another weapon's cooldown phase. Added `power.base_output` (150, raised from the D-023 recommendation's illustrative 100 so the existing 11-Flak-on-ring-1 test fixtures still fit) and `power.brownout_fraction` (0.1), plus `flak.power_demand` (10) and `mass_driver.power_demand` (25). 28 new headless checks (5 in `test_building_rules.gd`, 3 in `test_weapon_rules.gd`); full 17-suite run passes (70/360 respectively) and the T-023 baseline digest still matches byte-for-byte (`_cost_fixture` given a `power.base_output` override so its pre-existing 11-Flak load fixture is unaffected by the new rule). |

**T-037 scoping note for Kevin:** the spec allows a relay to be destroyed independently of its ring (e.g., a future Sapper elite targeting it directly, per §10.2). No such path exists in the current combat model — only a full 7-of-12 collapse removes a relay today. `PowerRules.chain_boundary` therefore treats "relay intact" as "ring not collapsed" rather than tracking relay HP separately. This is documented in `power_rules.gd`'s header and is a reasonable first-pass scope call (nothing yet can target a relay specifically), but it means brownout can currently only be triggered by losing a whole ring, not by a precision relay strike — revisit when Sapper (D-019, Phase 9) is implemented. Also not yet built: standalone relay cost/HP (30/75 from the D-023 recommendation) and a HUD brownout marker — both listed in the original recommendation but not reachable/needed yet since relays are currently only lost/restored as part of whole-ring collapse/reclaim (already implemented under D-022).

Next: all four Phase 7 rule layers approved this session are now implemented except D-021 assimilation (per-stack decay bookkeeping). After that, UI wiring for Repair/Reclaim/Armor Plating/Repair Node/Power is the remaining Phase 7 work.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-038 | UI wiring: Armor Plating, Repair Node, Repair, Reclaim | Luna | 🟢 Done | Structure tab gained four buttons alongside Ring Plate/Wall. Armor Plating and Repair Node are ordinary slot-based placements (`build_mode` routed through the existing `_place_build` dispatch, like Flak/Wall). Repair targets a wedge directly, no slot (like Wall). Reclaim needed a new dedicated path: `build_view.gd` gained a `_reclaim_ring`/`_reclaim_slot_count` virtual pair and a `reclaim` branch in `_unhandled_input` (parallel to the existing `expand` branch), since a collapsed ring reports zero slots today (nothing occupies it) but needs its *post-reclaim* slot count for relay-position selection — computed via a new virtual rather than reusing `_slot_count`, so normal empty-slot rendering on collapsed rings is untouched. Error messages for power/stack/full-HP/collapsed-ring rejections added to `_purchase_error`. New `tests/presentation/test_structure_view.gd` (13 checks) exercises all four buttons end-to-end including two rejection paths (repair an already-full wedge, reclaim a non-collapsed ring). Full 18-suite run passes. Capture: [T-038-structure-tab.png](docs/reviews/artifacts/T-038-structure-tab.png). |

T-038 review: this is presentation/input wiring only — no gameplay rule changed (T-035/036/037 already cover that). Kevin accepted the capture as-is for this testing stage. All of Phase 7's rules approved this session (D-022, D-027 subset, D-023) are now implemented, tested, and playable end-to-end. Only D-021 assimilation remains before Phase 7's full rule scope is complete.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-039 | D-021 assimilation (Option A) | Terra | 🟢 Done | Every machine payload gained an `assimilation_stacks: Array[float]` field (expiry timestamps), threaded through `_target_record`/the pool commit like the existing Tunneler fields. `_attack_surface` multiplies a machine's damage by `1.0 + 0.05×min(10, active stacks)` (`LiveSimulation._assimilation_multiplier`), reading stacks as they stood *before* this tick so a chain of destructions within one tick can't compound same-tick. A new per-tick pass, `_apply_assimilation`, runs once after movement+combat: prunes each machine's expired stacks (own 15s timer), then grants this tick's total destroyed-occupant count (`context.assimilation_grants`, incremented once per broken wall and once per occupant+wall a collapsing ring clears, counted *before* collapse clears them) to every machine with `hp>0`, capped at 10 stored stacks per machine. Future spawns start with no stacks (never retroactive). No new UI — assimilation is a passive enemy-side effect with no player action to wire up. 37 new headless checks in `test_live_simulation.gd` covering grant-on-wall-break, grant-on-collapse (exact occupant count, not a flat bonus), the 5%/stack damage effect, the +50% cap on both the multiplier and on storage, decay/pruning freeing room for new stacks, and future spawns receiving nothing retroactively. Full 18-suite run passes. |

**T-039 baseline note:** the new `assimilation_stacks` field changed `targets_snapshot()`'s shape for every machine, so the T-023 performance baseline digest (`tests/performance/baselines/`) needed deliberate re-recording — confirmed first that all 246 digests mismatched *uniformly* (consistent with a shape change, not a behavior change) before regenerating with `--record-cost-baseline`. See the baseline README's dated note.

**T-039 test-design note:** the first attempt at these fixtures put a "damage observer" machine at an open (unwalled) gap while a separate machine broke a wall elsewhere in the same ring. Per the already-approved D-066-068 wall rules, a machine always detours toward *any* reachable open gap — so once that wall broke, later ticks silently rerouted the observer toward the new opening too, corrupting the before/after damage comparison. Fixed by using fully sealed rings (every wedge walled, so D-066-068's sealed exception applies and each machine attacks its own local wall) and, for the cap/decay checks, fresh single-purpose simulations rather than reusing one sim across multiple wall-breaks (avoiding compounding gaps entirely). Worth remembering for any future fixture combining walls and machine positioning: an open gap anywhere in a ring can redirect machines that aren't obviously related to it.

**Phase 7 status: complete.** D-021, D-022, D-027 subset, and D-023 are all implemented, tested, and (except assimilation, which needs none) playable end-to-end.

**D-087 — 2026-09-07:** Kevin accepted Phase 7 as complete (Option A). The "growing world beyond three rings" presentation gap (A2 from the original audit) is explicitly carried forward as a named, open item — not resolved by this acceptance. Phase 8 is now open.

## Phase 8 — full tactical catalogue and abilities

Per FULL-GAME-TEST-PLAN.md and the remaining D-027 items, this phase covers the rest of the tactical catalogue (EMP Node, Lance Emitter, Point Defense, Debris Field, Tractor Lane, Occlusion Screen) and D-026 (ability numbers and kill-credit interaction for Focused Flare and EMP Burst).

**Rule briefing approved 2026-09-07:** Kevin approved D-088 (EMP Node, Option A: pulsed cooldown-gated area stun + minor damage), D-089 (Lance Emitter, Option A: discrete burst hitting every machine in its own wedge column), D-090 (Point Defense, Option A: zero range, own-wedge-only), D-091 (Debris Field, Option A: indestructible terrain, no HP, exempt from collapse accounting), D-092 (Tractor Lane, Option A: `PolarRouteField` path-cost steering, not teleport), D-093 (Occlusion Screen, Option A: fixed shadow tied to its own wedge column), and D-026 (Option A: ability kills award no energy) — all as recommended, in one bundled pass. All numeric values (radii, durations, damage, cooldowns, costs, ability numbers) are first-pass under D-033.

D-088 (EMP Node) is the one item needing new engine state before it can be built: `LiveSimulation`/machine payloads have no per-machine status-effect field yet (stun/slow), unlike everything else in Phase 7 which was pure numeric/occupant additions. Recommend building that status-effect plumbing first (shared by EMP Node and, later, EMP Burst per D-026), then the remaining five catalogue items, then abilities.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-040 | D-088 EMP Node (Option A: pulsed area stun) | Terra | 🟢 Done | New per-machine `stun_remaining: float` field (seconds), threaded through `_target_record`/the pool commit like the other base fields (payload-size heuristic for tunneler-field detection bumped from `> 5` to `> 6`). `LiveSimulation.step`'s movement loop now skips movement and attack entirely for a machine with `stun_remaining > 0`, decrementing it by the time it would have spent acting instead (clamped to zero, never negative) — applies uniformly to normal machines and Tunnelers alike, a first-pass scope call under D-033. `WeaponRules` gained `emp_node` to its weapon allow-list (fires like Flak/Mass Driver — cooldown, range, arc, cap, power demand, all generic by kind); on a nonlethal hit it also refreshes (never stacks past one pulse's duration, via `maxf`) the target's stun clock to `emp_node.stun_seconds`, applying no stun on a killing hit. `BuildingRules.place_weapon` and `RingPurchaseRules.validate_state`'s occupant allow-list both gained `emp_node`. Added `economy.emp_node_cost` (30) and an `emp_node` balance section (damage 1.0, cycle 3.0s, range 2.0 ring-widths, arc 360°, max_targets 8, power_demand 10.0, stun_seconds 1.5) to the schema and `testing.json`. 12 new headless checks (3 in `test_building_rules.gd`, 4 in `test_weapon_rules.gd`, 5 in `test_live_simulation.gd`); full 18-suite run passes. No UI yet — rule layer only, matching the Phase 7 pattern of batching UI wiring once more of the catalogue exists. |

**T-040 found a real regression, same shape as T-036's:** `PowerRules.ring_demand` and `PowerRules.can_afford` both had their own separate hardcoded `[&"flak", &"mass_driver"]` allow-lists (distinct from `WeaponRules`' combat-loop allow-list, which I updated first) — EMP Node would have been placeable for free, bypassing D-023's power-capacity check entirely, until `test_building_rules.gd`'s power-rejection check caught it. Fixed by introducing a single shared `PowerRules.POWERED_KINDS` constant used by both functions, so a future powered occupant kind needs updating in one place instead of three (`WeaponRules`, `ring_demand`, `can_afford`) separately. Confirms the Phase 7 "extend the stage-then-commit pattern" contract's lesson generalizes: every new occupant kind needs a pass through every place that enumerates occupants by kind, not just the placement rule and the combat loop.

**T-040 baseline note:** the new `stun_remaining` field changed `targets_snapshot()`'s shape again (same as T-039's `assimilation_stacks` change) — confirmed all 246 digests mismatched uniformly via `--cost-review` before regenerating with `--record-cost-baseline`, then reran clean (785 checks, 0 failures). See the baseline README's dated note.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-041 | D-089 Lance Emitter (Option A: discrete wedge-column burst) | Terra | 🟢 Done | Added `lance_emitter` to `WeaponRules`' weapon allow-list, `BuildingRules.place_weapon`'s kind list, `RingPurchaseRules.validate_state`'s occupant allow-list, and `PowerRules.POWERED_KINDS` (the shared constant T-040 introduced specifically so this next weapon wouldn't repeat the same three-separate-allow-list mistake). Target selection needed a genuine branch, not just a numeric add: instead of the generic bearing/arc filter every other weapon uses, `kind == &"lance_emitter"` selects every living, targetable machine whose `position.wedge` matches the weapon's own wedge — any angular offset within that wedge, any ring within range — leaving the rest of the fixed-order combat loop (cooldown, range cutoff, cap, flat per-target damage) untouched and shared with Flak/Mass Driver/EMP Node. No new payload fields, so the T-023 baseline was unaffected (confirmed via `--cost-review`, still clean at 785/0, no re-record needed). Added `economy.lance_emitter_cost` (60) and a `lance_emitter` balance section (damage 8.0, cycle 4.0s, range 6.0 ring-widths, arc_degrees 360 — present for schema consistency but unused by this kind's selection logic, max_targets 20, power_demand 30.0) to the schema and `testing.json`. 8 new headless checks (3 in `test_building_rules.gd`, 5 in `test_weapon_rules.gd` verifying same-wedge-different-ring hits, cross-wedge exclusion at equal range, and flat per-target damage); full 18-suite run passes on the first try — no regressions found this time. No UI yet, matching the batched-UI-at-the-end pattern. |

**Playtest tuning — 2026-09-07 (D-033):** Kevin reported dying at roughly 20-21 seconds during his own testing, unable to get real play time on Phase 7/8 features. Under D-033's delegated numeric-tuning authority, adjusted `data/balance/testing.json` for survivability: `economy.kill_energy` 1→2, `starting_test_setup.energy_in_flak_purchases` 1→8 (startup grant 20→160 energy), and added a new field `pressure.spawn_delay_seconds` (0→10.0) so no normal machine is due before 10 seconds of match time, giving a genuine preliminary build window (implemented in `MachineSpawnRules.arrivals_between`/`spawn_descriptor`; Tunnelers are unaffected, keeping their own independently-tuned `first_arrival_seconds`). All three values are explicitly provisional testing numbers, not balance decisions — Kevin's own play is the adjustment mechanism per D-033, not a pre-approval round. Updated ~15 test assertions across `test_building_rules.gd`, `test_wall_rules.gd`, `test_weapon_rules.gd`, `test_live_simulation.gd`, `test_build_view.gd`, `test_live_view.gd`, and `test_wall_view.gd` that hardcoded the old startup energy (20) or kill reward (1); added `pressure.spawn_delay_seconds: 0` overrides to the rule-level scheduling-math test fixtures (`test_machine_spawn_rules.gd`'s base profile, `test_live_simulation.gd`'s `_sim()`/`_tunnel_sim()` helpers) so those suites keep testing the underlying mechanism independent of this gameplay-only knob, plus a small dedicated `_spawn_delay_checks` block verifying the delay itself. Full 18-suite run passes; T-023 baseline confirmed unaffected (no new payload fields, no fixture depends on default economy/spawn-timing values).

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-042 | D-090 Point Defense (Option A: zero-range, own-tile-only) | Terra | 🟢 Done | Added `point_defense` to `WeaponRules`' weapon allow-list, `BuildingRules.place_weapon`'s kind list, `RingPurchaseRules.validate_state`'s occupant allow-list, and `PowerRules.POWERED_KINDS`. Target selection is the strictest of the four new weapons: `kind == &"point_defense"` bypasses range/arc geometry entirely and requires an exact cell match — `target.position.ring == ring and target.position.wedge == wedge` — so it engages only a machine already standing in its own ring+wedge (a Tunneler surfacing there, a Transfer landing there), never a neighboring wedge on the same ring and never the same wedge on a different ring (the one thing that does distinguish it from T-041's Lance Emitter, which spans every ring in its wedge column). `range_ring_widths`/`arc_degrees` stay in the schema for catalogue consistency but are unused by this kind's selection, matching Lance Emitter's precedent. No new payload fields, so the T-023 baseline was unaffected (confirmed via `--cost-review`, clean at 785/0). Added `economy.point_defense_cost` (25) and a `point_defense` balance section (damage 3.0, cycle 0.1s — the fastest in the catalogue, matching "high rate of fire", range 0.5 ring-widths, arc 360, max_targets 1, power_demand 8.0) to the schema and `testing.json`. 9 new headless checks (3 in `test_building_rules.gd`, 6 in `test_weapon_rules.gd` verifying the exact-cell match against both a same-wedge-different-ring and an adjacent-wedge-same-ring decoy); full 18-suite run passes on the first try. No UI yet, matching the batched-UI-at-the-end pattern. **All three weapon-catalogue items needing new selection logic (D-089, D-090) plus the one needing new engine state (D-088) are now done; remaining Phase 8 rule work is entirely Terrain (D-091/092/093) and abilities (D-026).** |

## Phase 8 continuation audit and assignments

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-053 | Hotkeys and compact interim UI | Luna | 🟢 Done | Original delivery verified; T-063 newer30-suite baseline includes its418-check suite. Further productionUI inT-067. |
| T-054 | Hotkeys/UI integration check | Sol | ⚫ Cancelled | Superseded byT-063 native30-suite verification against newerClaude source; no unchecked queuedrun remains. |
| T-055 | Decouple relay from wedge-slot occupancy; per-wedge slot density | Terra | 🟢 Done | docs/contracts/T-055-relay-and-slot-capacity.md; D-104/D-105 both approved (Option A, default slot count 2). Implemented directly rather than delegated — T-053's own suite was already passing cleanly by the time this started, so the collision risk that motivated delegation didn't materialize. |

### T-055 completion notes

Ring records' `relay` field is now `{"active": true}` (owned, non-collapsed) or `{}` (never owned / collapsed) — no wedge or slot reference, matching D-104. `RingPurchaseRules.quote_next_ring`/`purchase_next_ring`/`quote_reclaim_ring`/`reclaim_ring` dropped their `relay_wedge`/`relay_slot` parameters entirely; a ring purchase or reclaim is now a single click with no follow-up slot selection — this also directly resolves Kevin's "I don't see how to buy the next ring" confusion, since the flow is now simpler than what he tried. `starting_test_setup.relay_wedge`/`relay_count` removed from the schema (no longer meaningful). `scaling.slots_per_wedge_per_ring` raised 1→2 per D-105, so ring 1 now gives 2 slots per wedge instead of 1.

UI: `build_view.gd`'s expand/reclaim input branches now just confirm a click lands on the correct ring band (no slot geometry needed); `live_view.gd`/`art_preview.gd` inherit this. `ring_status_hud.gd`'s relay marker changed from a per-wedge mark to a single ring-level indicator (drawn at a fixed reference angle), since there's no wedge for it to point at anymore.

Test impact was large as flagged in the contract: roughly 40 call sites across `ring_purchase_rules.gd`, `building_rules.gd`, `live_simulation.gd`, `build_view.gd`, `live_view.gd`, `ring_status_hud.gd`, and ~15 test files needed mechanical argument-count fixes plus relay-shape assertion updates (`{"wedge":.., "slot":..}` → `{"active": true}`). Two non-mechanical issues surfaced and were fixed: (1) several `test_weapon_rules.gd` boundary-precision checks assumed the starter Flak sits at exact wedge-center bearing, true only when a wedge has exactly 1 slot — fixed by pinning `scaling.slots_per_wedge_per_ring: 1` for that scoped test section rather than changing the live default; (2) `test_terrain_rules.gd`'s "occupied/out-of-bounds slot" check used wedge 6 (the old relay wedge, now free) and slot index 2 (now in-bounds under the new 4-slot ring-2 dimension) as its two probes — both needed replacing with genuinely-occupied/out-of-bounds positions under the new dimensions.

**T-023 baseline note:** re-recorded after confirming the mismatch. Investigated a real change hidden inside the uniform 246/246 mismatch: the `sustained_ring3_angular` cost fixture's hit-count pattern shifted (occasional 30/35-hit volleys → regular 15-hit volleys). Isolated the cause by temporarily reverting only `slots_per_wedge_per_ring` to 1 (keeping the relay change) and reproducing the old pattern exactly — the fixture places a Flak at a literal `slot=1`, and `BuildingRules.slot_position` computes bearing from `(slot+0.5)/slot_count`; doubling ring 3's slot count moved that Flak's aim off the old wedge-center bearing. This is a real, correct consequence of D-105, not a bug. Re-recorded and reran clean (785/0). See `tests/performance/baselines/README.md`.

Full 25-suite run passes; no stray Godot processes.
| T-056 | Weapon-fire projectile/impact visuals | Luna | Done | Completed in T-067: bounded cosmetic hit feedback, verified pause/expiry/settings; combat timing unchanged. |

2026-09-07 review update: T-043 and T-044 accepted after source review and native Windows import plus all 19 suites passing (logs: .godot/test-logs/run-20260907-211539-711-40748). T-045 final prompt edits were separately rechecked, and the later T-052 full 24-suite run covers the final integrated source. Rows below retain their task contracts and handoff context.

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-046 | Directed route costs for Tractor Lane | Sol | 🟢 Done | docs/contracts/T-046-directed-route-costs.md; backward-compatible core API. |
| T-047 | Playable expansion beyond three rings | Luna | 🟢 Done | docs/contracts/T-047-growing-world-view.md; closes D-087 carryover after T-045 freeze. |
| T-048 | Solar ability rules and atomic live casts | Terra | 🟢 Done | docs/contracts/T-048-solar-ability-rules.md; D-097 approved; UI follows gameplay review. |
| T-049 | Playable industrial/painterly art comparison | Luna | 🟢 Done | docs/contracts/T-049-playable-art-comparison.md; follows T-047; D-098 approved experiments. |
| T-050 | Terrain catalogue and safe live routing | Terra | 🟢 Done | docs/contracts/T-050-terrain-rules.md; D-099/D-100 approved; follows T-048 review. |
| T-051 | Terrain and solar controls in live play | Luna | 🟢 Done | docs/contracts/T-051-terrain-and-ability-view.md; after T-050 rule review and T-049 freeze. |
| T-052 | Phase 8 integrated correctness checkpoint | Sol | 🟢 Done | docs/contracts/T-052-phase8-integration-check.md; requires T-049/T-050/T-051 source freeze. |

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-043 | Correct snapshot/status/weapon contracts and occupied repair | Terra | 🟢 Done | docs/contracts/T-043-phase8-gameplay-corrections.md; D-094 approved; root probe reproduced repair freeze and snapshot alias. |
| T-044 | Native Windows clean-import correctness runner | Sol | 🟢 Done | docs/contracts/T-044-windows-test-runner.md; scripts only; no export or baseline changes. |
| T-045 | New weapon UI and audited functional feedback | Luna | 🟢 Done | docs/contracts/T-045-phase8-weapon-view.md; EMP/Lance/Point Defense plus missing labels, power errors and quote feedback. |

Initial audit 2026-09-07: all 18 then-existing suites exited 0. Historical logs .godot/phase8-audit-test_*.log; additional probe .godot/phase8-audit-probe.log exposes defects not covered by those tests. D-021/D-022/D-023 stale pending headers were reconciled to their existing approvals, not newly approved. D-033 permits first-pass numbers for approved mechanics. T-047 subsequently closed playable growth beyond three rings. Independent relay vulnerability/rebuild, brownout presentation and recovery payback remain follow-ups. Supplied art references led to the approved D-098 experiments; D-030 final art remains open.

**Astra review pass — 2026-09-07:** reviewed Codex's completed Phase 8 continuation work (T-043 through T-052, T-053/054 in flight) against Kevin's live-test feedback. Under D-033, raised `starting_test_setup.energy_in_flak_purchases` 8→10 (startup grant 200, exactly enough to place a Flak in all 11 non-relay starter wedges alongside the pre-placed one) per Kevin's explicit request. Updated all hardcoded startup-energy/derived-transaction assertions across `test_live_view.gd`, `test_hotkeys_compact_ui.gd`, `test_growing_world_view.gd`, `test_build_view.gd`, `test_art_preview.gd`, `test_live_simulation.gd`, `test_building_rules.gd`, `test_wall_rules.gd`, and `test_wall_view.gd` (160→200, and its downstream derived values 140→180/155→195/162→202). Full 25-suite run passes, no stray processes.

Kevin also raised, and Astra is working through separately (not yet implemented): (1) relay should not occupy a wedge slot and should be independently killable rather than only lost with full ring collapse — aligns with the spec and the already-tracked "independent relay targeting/destruction" follow-up, full realization likely belongs with Phase 9's Sapper elite; (2) the next-ring purchase control exists today (Ring Plate / hotkey Q, per `docs/CONTROLS.md`) — likely a discoverability issue, not a missing feature; (3) weapon fire has no projectile visual, hits are instant/hitscan — a presentation-only gap, proposed as a new task; (4) done, see above; (5) art-direction style guide outline drafted at `docs/art-direction-style-guide.md`, to be worked through with Kevin separately; (6) Kevin's proposed Flak rework (360°, 1.1 ring-width radius, "split on either side") is a real Tier 2 rule change with role-overlap implications versus Point Defense/Mass Driver — presented as a decision, not yet implemented. See the chat briefing for full detail on each.







## Feature completion — 2026-09-08

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| T-062 | Phase9 gameplay and remaining-rule audit | Terra | 🟢 Done | docs/reviews/T-062-gameplay-audit.md; fixes assignedT-065. |
| T-063 | Current native correctness baseline and persistence readiness | Sol | 🟢 Done |30/30suites, actualexit0; docs/reviews/T-063-baseline.md. Supersedes queuedT-054 against newer source. |
| T-064 | Industrial UI/16:9 design and integration audit | Luna | 🟢 Done | docs/reviews/T-064-ui-plan.md; root reviewed plan, implementationT-067. |
| T-065 | Rule corrections, run choices and reward accounting | Terra | 🟢 Done |3968checks pass;246stored digests unchanged; source frozen. docs/reviews/T-065.md. Application integration remainsT-067/T-068. |
| T-066 | Profile persistence and private build tooling | Sol | 🟢 Done | 59 checks pass; persistence API frozen. Export tooling smoke passed; final package remains T-068. |
| T-067 | Industrial 16:9 application, full session UI and tutorial | Luna | Done | Root visual review accepted; 7771 focused checks and 37 native capture checks pass. Rendered 1000-actor capacity fails target; explicit report T-067. |
| T-068 | Integrated feature-complete candidate verification | Astra/coordinated lane owners | Verified | Final39/39 suites and actual exported application lifecycle/reload pass; source identity221files verified. Large-crowd performance fails target and is explicitly carried forward. Final source archive follows documentation freeze. |
| T-069 | Correct unrepresentable movement subtraction residue | Terra | Done | Root reviewed narrow guard; 1545 checks, 246 unchanged digests and all 18 original mixed fixtures pass. docs/reviews/T-069.md. |
| T-070 | Local run diagnostics and reproduction trace | Sol with Luna hooks | Done | 59 helper checks plus application recorder checks pass. Frozen core/UI hooks; final packaged identity and aggregate in T-068. No resume/replay UI. |

| T-071 | Strategic-zoom placement and label legibility | Luna | Done | 539 focused checks pass; root accepts final strategic PNG. Final rendered samples retain1000 actors and remain over budget. docs/reviews/T-071.md. |

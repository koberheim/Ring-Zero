# T-010 — Purchases, weapon placement, and automatic combat rules

**Owner:** Terra. **Coordinator:** Astra. **Date:** 2026-09-06.
**Authority:** D-025 Option A and D-047 Option A approved. All armed buildings attack and select targets automatically; no building aim/fire command. Solar abilities will use player targeting later but remain outside this slice.
**Read:** this brief, docs/contracts/T-008-purchases.md, and only existing files needed to modify: balance_profile.gd, testing.json, balance tests. Core API is summarized here; do not read full spec/root logs.

## Files

Own src/gameplay/ring_purchase_rules.gd, src/gameplay/building_rules.gd, src/gameplay/weapon_rules.gd, tests/gameplay/test_building_rules.gd, tests/gameplay/test_weapon_rules.gd, docs/reviews/T-010.md.
May update data/balance/testing.json, src/gameplay/balance_profile.gd, tests/gameplay/test_balance_profile.gd, and docs/balance-data.md for approved numeric fields only. Adjacent .uid allowed.
Do not change project/main scene, core scripts, or presentation. No spawning, pathing, pooling, update loop, collapse resolver, power, wall-edge model, or abilities. Implement independent state transitions and combat stepping against supplied targets; report all limitations.

## T-008 implementation

Implement T-008 API exactly in RingPurchaseRules. Do not allow malformed state or invalid profile to throw an exception; return {ok:false, state:null or quote:null, errors:PackedStringArray}. Recheck current eligibility on every purchase. Validate shape, scalar types including bool rejection, finite amounts, ring/slot identifiers, wedge ranges, unique occupancy, relay-reference agreement, and complete contiguous ring records. Preserve input snapshots on success and failure. Quotes include affordable:bool and still return a valid price when funds are insufficient; purchase rejects unaffordable quotes before mutation.

Generic state validation allows recognized occupant kinds flak, mass_driver, relay and finite wedge HP from 0 through max_hp. HP 0 denotes a broken wedge for eligibility; no damage/collapse implementation here. A pre-collapse state with a broken wedge is legitimate input but cannot expand from that ring.

Initial placement records explicitly give ring/wedge/slot/kind; validate starter counts and approved wedge identifiers from the profile. Missing or unusable starter records fail clearly. Ring 1 at current settings has Flak (12,0), relay (6,0), energy 20. Default startup helper below constructs these records from profile fields; if changed counts cannot be represented by that simple approved setup, fail clearly and direct the caller to explicit T-008 placements rather than inventing extra locations.

## BuildingRules public API

BuildingRules extends RefCounted:
- static func create_default_testing_state(profile: BalanceProfile) -> Dictionary
- static func slot_position(ring:int, wedge:int, slot:int, slot_count:int) -> PolarPosition
- static func slot_for_fraction(angular_fraction:float, slot_count:int) -> int
- static func place_weapon(state:Dictionary, profile:BalanceProfile, ring:int, wedge:int, slot:int, kind:StringName) -> Dictionary

place_weapon uses T-008 transaction result shape and the same state validation (shared internal helper allowed in RingPurchaseRules). Only flak and mass_driver are purchasable in this task. Relay is included only through ring purchase. Check owned unbroken wedge, valid slot, empty occupancy, affordable current data price, recognized kind. Deduct once, place one record, return a deep copy. Failed attempts never spend or mutate input. No selling/refunds.

slot_position returns null for invalid inputs, otherwise PolarPosition(ring,wedge,0.5,(slot+0.5)/slot_count). All slots are evenly spaced across the wedge at its middle radius. No world position is stored in occupants.
slot_for_fraction maps a valid [0,1) clockwise fraction to floor(fraction*slot_count), otherwise -1. This maps mouse selection to exact slot IDs without duplicated UI rules.
PolarPosition public fields are ring:int, wedge:int, radial_fraction:float, angular_fraction:float; constructor accepts those four in that order. PolarGrid exposes WEDGE_COUNT=12, RING_WIDTH=96, CORE_RADIUS=96. Its constructor PolarGrid.new(ring_count:int=3) is O(1); polar_to_world(position) and is_valid_position(position) are INSTANCE methods. Make a grid covering supplied target/building rings without enumerating all cells. Core ring0 has wedge0, radius fraction [0,1), angle fraction [0,1) across a full turn; at radial_fraction0 its canonical angular_fraction is0. Invalid polar_to_world emits a diagnostic and returns INF, so validate before conversion. No hard three-ring limit in rules; callers pass their scene limit.

## Numeric data amendment

Add mass_driver.arc_degrees = 360.0, validated with the same arc rule as Flak. All ranges/damage/cycles/arcs/target caps remain profile-driven. Add nothing to the profile for pending spawn/path settings. Update the accepted data tests/doc for this required schema field without adding gameplay defaults in code.

## WeaponRules public API and supplied target contract

WeaponRules extends RefCounted:
- static func step(state:Dictionary, profile:BalanceProfile, targets:Array[Dictionary], cooldowns:Dictionary, delta_seconds:float) -> Dictionary

Return {ok:bool, targets:Array[Dictionary], cooldowns:Dictionary, hits:Array[Dictionary], kill_ids:Array[int], energy_awarded:number, errors:PackedStringArray}. On invalid input return no partial updated results (empty result collections and energy0). Never mutate input targets/state/cooldowns. Do not change state.energy here; caller later banks energy_awarded once per completed tick.

Target record: {id:int >=0, position:PolarPosition, hp:finite >=0}. IDs unique; polar position may lie beyond owned rings, but must be geometrically valid (ring>=0, core wedge0/band wedge1–12, normalized finite fractions). Clone mutable PolarPosition objects when returning target records. World vectors may be derived temporarily for distance/arc checks, never persisted.

Cooldown key is stable StringName formatted "ring:wedge:slot", value finite seconds >=0 until the next eligible shot. Missing keys mean ready. Ignore/remove stale keys whose weapon no longer exists; reject malformed keys/types instead of throwing. Dead/broken-wedge weapons never fire. Relay has no attack.

Process weapons in deterministic ring/wedge/slot order. For each fixed update, reduce cooldown toward zero by delta_seconds. A ready weapon automatically selects living eligible targets, nearest world-space distance then lowest target ID for exact distance ties. Flak faces outward along its OWN SLOT's radial bearing, with the approved data arc centered on that direction. Mass Driver has full-circle eligibility at 360; if that data is tuned narrower, use the same radial reference. Include range/arc boundaries with a documented small numerical tolerance. No line-of-sight/obstacle rule is invented: pathing/terrain is separate.

Apply instantaneous damage up to max_targets, clamp target HP to zero, and emit hit {weapon_id:StringName,target_id:int,damage:number} using actual HP removed. Do not hit dead targets; different weapons see earlier hits in the same update. When a live target first reaches zero, emit its ID exactly once and award profile economy.kill_energy once. No friendly targets are present, hence no friendly-fire path. Slot assignment is the only player input to armed buildings.

A fixed update is expected to be at most one physics tick (1/60 second); validate delta_seconds finite and >=0, and implement at most one volley per weapon per call. Set a firing weapon's remaining cooldown to its data cycle. This initial contract is a deterministic fixed-step combat function, not an elapsed-time catch-up simulation. Do not let an empty target list consume a ready weapon's cycle. State limitations in the report; frame-loop timing belongs to Sol.

## Done and review

Godot executable E:/Godot/Godot_v4.7.2-stable_win64.exe, process APPDATA/LOCALAPPDATA under workspace .godot and local logs. Run import, affected balance suite, and focused new rule suites. No unchanged visual/core suites until integration needs them.

Meaningful checks: T-008 startup/price/atomicity tests; changed balance values change derived grants, purchases, HP and damage; slot geometry matches approval; illegal placement never spends; candidate ring limit enforced without grid cap; all 12 inward wedges required; partial HP still eligible; relay uses one slot.
Weapon checks: automatic firing without commands, nearest and deterministic ties, Flak arc exclusion/inclusion, 360 Mass Driver, range limits, target cap, cooldown no early refire/empty-target readiness, dead targets/no duplicate reward across weapons and successive calls, input/returned-position isolation, malformed states/targets/cooldowns, no relay attack, broken wedge suppresses attack. T-008 tests may share test_building_rules.gd rather than create a second near-duplicate runner.

Record actual counts/commands and limitations in docs/reviews/T-010.md. Deliver for Astra review. No UI or enemy generation in this task.

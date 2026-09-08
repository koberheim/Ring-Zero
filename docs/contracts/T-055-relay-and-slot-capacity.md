# T-055 — Relay decoupling and per-wedge slot capacity

Owner: Terra (rules), with a follow-up UI pass (Luna) for the simplified ring-purchase flow. Implements D-104 (approved) and D-105 (numeric slot count pending Kevin's confirmation — default to `scaling.slots_per_wedge_per_ring = 2` unless told otherwise before starting). Sequence after T-053/T-054 freeze: an audit found roughly 105 call sites across 29 files touching relay wedge/slot parameters, including the exact UI files (`build_view.gd`, `live_view.gd`, `art_preview.gd`) T-053 is mid-edit on. Do not start until Astra confirms T-053/T-054 have frozen source.

## D-104 — relay decoupling

Every owned, non-collapsed ring has exactly one relay; it no longer occupies a wedge slot and is never placed via a slot click. Concretely:

- `RingPurchaseRules`: ring records' `relay` field stops carrying `{wedge, slot}` and becomes a simple presence marker (e.g. `{"active": true}` when present, `{}` when the ring is collapsed) — no positional data yet, since Kevin explicitly wants it "floating," not attached to a node.
- `validate_state` drops the relay-wedge/occupant cross-check and drops `&"relay"` from the occupant-kind allow-list entirely — a relay is never an occupant dictionary in a wedge.
- `quote_next_ring`/`purchase_next_ring` and `quote_reclaim_ring`/`reclaim_ring` drop their `relay_wedge`/`relay_slot` parameters — buying or reclaiming a ring is now relay-free by construction, one action.
- `BuildingRules.create_default_testing_state` places only the starter Flak; the relay is automatic on ring creation, not a placement entry. `starting_test_setup.relay_wedge`/`relay_count` become unused — remove them from the schema/testing.json cleanly rather than leaving vestigial fields, and update every test that references them.
- UI: `build_view.gd`/`live_view.gd`/`art_preview.gd`'s expand/reclaim flow drops the "now click a slot to place the relay" step. A ring purchase becomes a single click/hotkey (Q) with no follow-up placement. `ring_status_hud.gd`'s relay marker needs a replacement visual cue since there's no wedge/slot to point at (a simple ring-level indicator is enough for now — exact presentation is Luna's call).

**Explicitly out of scope for T-055:** independent relay targeting/destruction (killing the relay, brownout triggering from that instead of full collapse). That mechanic needs an attacker before it means anything — design it together with Sapper in the Phase 9 briefing, not here. `PowerRules.chain_boundary`'s existing "relay intact == ring not collapsed" simplification stays exactly as-is; this task does not touch it.

## D-105 — per-wedge slot density

Raise `scaling.slots_per_wedge_per_ring` from 1 to the value Kevin confirms (default assumption: 2) in `data/balance/testing.json`. This is a pure numeric retune of an already-built mechanic (ring N already gets N slots per wedge; this changes the multiplier, nothing else). No targeting/rule code changes anywhere. Combined with D-104, every ring-1 wedge should end up with 2 free weapon slots once the relay no longer eats one.

## Test impact

The two changes together touch a large, previously-mapped set of call sites:
- `ring_purchase_rules.gd`, `building_rules.gd`, `live_simulation.gd` (rule layer, relay shape and parameter removal)
- `build_view.gd`, `live_view.gd`, `art_preview.gd`, `ring_status_hud.gd` (presentation)
- Test files with direct `purchase_ring`/`purchase_next_ring`/`quote_expansion`/`reclaim_ring`/`quote_reclaim` call sites (grep confirmed hits in `test_live_simulation.gd`, `test_building_rules.gd`, `test_live_view.gd`, `test_wall_view.gd`, `test_tunneler_view.gd`, `test_structure_view.gd`, `test_terrain_ability_view.gd`, `test_hotkeys_compact_ui.gd`, `test_weapon_catalogue_view.gd`, `test_wall_rules.gd`, `test_wall_navigation.gd`, `test_tunneler_rules.gd`, `test_terrain_rules.gd`, and the capture_*.gd scripts) — expect most of these need a mechanical argument-count edit, not a logic change.
- The startup energy check (currently 200, giving exactly enough for a Flak in every non-relay ring-1 wedge under the old 1-slot model) will need reassessment once ring-1 has 2 slots per wedge — do not silently change it without flagging the new math to Astra/Kevin, since it interacts with D-033 testing tuning already recorded this session.

## Done condition

Full test suite (all discovered suites, currently 25) passes with no new failures. `--cost-review` confirms whether the T-023 performance baseline needs a deliberate, documented re-record (it will, if any target/state snapshot shape changed — check before regenerating, per this project's standing rule). Report exact call-site count touched, any relay-shape or slot-count deviation from this contract, and screenshots of the simplified one-click ring purchase flow. Freeze source for Astra's review before considering D-104/D-105 fully closed.

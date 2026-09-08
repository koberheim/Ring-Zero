# T-008 — Startup and whole-ring purchase contract

**Owner:** Astra. **Status:** Contract prepared; no consumer implementation assigned.
**Approved rules:** D-010–D-015, D-040, D-041, D-044, D-045. T-007 supplies validated balance data.
**Scope:** Data transitions for startup and expansion. Presentation/input is gated by D-025; enemy rules and combat are separate. No power behavior, retaking, or assimilation.

## Ownership and future files

Terra will own src/gameplay/ring_purchase_rules.gd and tests/gameplay/test_ring_purchase_rules.gd when assigned. Luna will consume the result for the build UI after its brief is approved. Neither changes PolarGrid or BalanceProfile. This is an interface contract, not permission to start a feature.

## State and identifiers

Use a plain Dictionary snapshot, separate from the visible inspection grid:
- energy: finite nonnegative number.
- rings: Dictionary keyed by positive ring index.
- Each ring record: { wedges: Dictionary, relay: { wedge: int, slot: int } }.
- Each wedge record keyed 1–12: { hp: number, max_hp: number, slot_count: int, occupants: Dictionary }.
- Occupants keyed by zero-based slot: { kind: StringName }. This contract uses flak and relay only.
- Relay must also occupy its recorded normal slot; the separate ring reference identifies it without duplicating its health or power state.

PolarGrid owns the fixed 12-wedge count. Slots have stable integer identifiers; physical slot locations, wall-edge occupancy, weapon aiming, and their presentation are outside this contract. Do not invent their geometry.

Transactions return { ok: bool, state: Dictionary or null, errors: PackedStringArray }. Return a deep-copied state on success, no partial state on failure, and never mutate the caller's input. Do not round computed costs silently. The current approved linear profile yields integer charges; later fractional-cost presentation/rounding must be settled before a tuned profile needs it.

## API

RingPurchaseRules extends RefCounted:
- static func create_testing_state(profile: BalanceProfile, placements: Array[Dictionary]) -> Dictionary
- static func quote_next_ring(state: Dictionary, profile: BalanceProfile, relay_wedge: int, relay_slot: int, ring_limit: int) -> Dictionary
- static func purchase_next_ring(state: Dictionary, profile: BalanceProfile, relay_wedge: int, relay_slot: int, ring_limit: int) -> Dictionary

Quote returns { ok: bool, quote: Dictionary or null, errors: PackedStringArray }, with quote { ring: int, cost: number, wedge_hp: number, slots_per_wedge: int, relay_wedge: int, relay_slot: int, affordable: bool }. Structurally eligible quotes succeed even without enough funds so UI can show the price; purchase rejects affordable=false before mutation. No quote changes ownership or funds. For a later purchase, recompute eligibility/cost from current state; do not trust a stale quote.

## Testing startup

Create the configured owned rings with all wedges intact, HP from the profile, and configured slot count per ring. placements explicitly supplies { ring, wedge, slot, kind } records, so no hidden placement fallback exists.

For the approved testing profile, the caller supplies Flak at (1,12,0) and relay at (1,6,0). Validate supplied records against available rings/slots and the configured starter counts and wedge identifiers. If a later profile changes those counts, the caller must supply matching deliberate positions, not an invented layout.

The starting grant equals economy.flak_cost times starting_test_setup.energy_in_flak_purchases. Do not charge for starter buildings or grant passive income. Testing startup does not select final gameplay or implement the tutorial.

## Expansion rules

For the existing contiguous, pre-collapse owned rings, candidate ring is the current outermost plus one. The configured slice ring limit is 3, passed as ring_limit; never bake 3 into the grid or generic service.

All 12 wedges of the immediately inward ring must exist with HP above zero. “Intact” here means not broken, not necessarily at full HP. A broken wedge blocks this purchase. Collapsed-ring/reclamation eligibility remains outside this contract under D-020/D-022; do not treat purchase as repair or silently recreate an old ring.

Cost = PolarGrid.WEDGE_COUNT * economy.ring_plate_base_cost * pow(candidate_ring, scaling.claim_cost_ring_exponent).
Wedge max HP = health.wedge_base_hp * pow(candidate_ring, scaling.wedge_hp_ring_exponent).
Slots per wedge = candidate_ring * scaling.slots_per_wedge_per_ring.
Reject nonfinite or otherwise unusable computed results with clear errors; never clamp or mint funds.

Validate relay wedge 1–12 and zero-based slot below slots_per_wedge. On success, subtract the cost once, establish all 12 wedges at full HP, and occupy the chosen slot with the included relay. There is no separate relay cost and no power calculation. Invalid target, funds, state, or eligibility leaves everything unchanged. No individual-wedge purchase or deliberate initial omission is offered.

## Verification required before acceptance

Use the accepted data loader with current and overridden profiles. Check default startup positions and 20-energy derived grant, then changed Flak cost changing the grant. Check ring-2 price 240 and ring-3 price 360, scaled HP/slots, all 12 wedges created together, relay slot occupied, and one deduction. Check every failure path leaves the original state unchanged: insufficient funds, broken inward wedge, bad relay identifiers, ring limit, malformed state, and stale quote eligibility changes. Check partially damaged but unbroken wedges remain eligible.

No source implementation is assigned by this contract. A subsequent task brief must fix any remaining consumer/UI choices, list actual allowed files, and require review before integrating with the running scene.

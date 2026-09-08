class_name PowerRules
extends RefCounted
## D-023 Option B: a fixed per-ring output table, checked only at placement
## time and at combat time for existing occupants — never recomputed as a
## continuous per-tick share (kept out of the combat hot path deliberately).
##
## Simplification noted for Kevin (Phase 7, first pass): the spec allows a
## relay to be destroyed independently of its ring (e.g. a future Sapper
## elite targeting it directly). No such independent-relay-destruction path
## exists yet — only full 7-wedge ring collapse removes a relay today. Until
## a relay can be targeted on its own, "relay intact" here means "ring not
## collapsed." Revisit when Sapper (D-019, Phase 9) is implemented.

## The outermost ring in an unbroken non-collapsed chain from ring 1. Power
## flows strictly outward (spec §8), so a break anywhere in the chain drops
## every ring beyond it to brownout, regardless of that further ring's own
## state.
##
## D-108: a ring whose own relay_hp has been drained to zero by a Sapper is
## not collapsed, but per D-108 it browns out - both its own output and the
## chain beyond it - exactly like a collapsed ring already does, without the
## Sapper needing to touch a single wedge.
static func chain_boundary(state: Dictionary) -> int:
	var boundary := 0
	for ring in range(1, state.rings.size() + 1):
		var record: Dictionary = state.rings[ring]
		if record.get("collapsed", false) or float(record.get("relay_hp", 1.0)) <= 0.0:
			break
		boundary = ring
	return boundary

static func ring_output(state: Dictionary, profile: BalanceProfile, ring: int) -> float:
	var base: float = float(profile.value("power.base_output")) * pow(ring, profile.value("scaling.power_ring_exponent"))
	if ring > chain_boundary(state):
		base *= float(profile.value("power.brownout_fraction"))
	return base

const POWERED_KINDS: Array[StringName] = [&"flak", &"mass_driver", &"emp_node", &"lance_emitter", &"point_defense"]

static func ring_demand(state: Dictionary, profile: BalanceProfile, ring: int) -> float:
	var total := 0.0
	for plate in state.rings[ring].wedges.values():
		for occupant in plate.occupants.values():
			if occupant.kind in POWERED_KINDS:
				total += float(profile.value("%s.power_demand" % occupant.kind))
	return total

## Placement-time check only, per D-023: would adding one more `kind` occupant
## still fit within this ring's current output? Existing occupants are never
## re-checked or displaced by this call.
static func can_afford(state: Dictionary, profile: BalanceProfile, ring: int, kind: StringName) -> bool:
	if kind not in POWERED_KINDS:
		return true
	var demand: float = float(profile.value("%s.power_demand" % kind))
	return RingPurchaseRules.number(demand) and ring_demand(state, profile, ring) + demand <= ring_output(state, profile, ring) + 1e-9

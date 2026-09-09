class_name FortressStatus
extends RefCounted
## Fresh scalar projection of authoritative state; no retained simulation refs.
const Power = preload("res://src/gameplay/power_rules.gd")
const CRITICAL_FRACTION := 0.25 # existing live-view threshold, unchanged

static func records(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not state.has("rings"): return result
	var boundary := Power.chain_boundary(state)
	for ring in range(1, state.rings.size() + 1):
		var source: Dictionary = state.rings[ring]
		var collapsed := bool(source.get("collapsed", false))
		var relay_active: bool = not collapsed and not source.get("relay", {}).is_empty() and float(source.get("relay_hp", 1.0)) > 0.0
		var brownout := ring > boundary
		var wedges: Array[String] = []
		var detail: Array[Dictionary] = []
		for wedge in range(1, 13):
			var plate: Dictionary = source.wedges[wedge]
			var hp := float(plate.hp)
			var maximum := float(plate.max_hp)
			var fraction := clampf(hp / maximum, 0.0, 1.0) if maximum > 0 else 0.0
			var status := "collapsed" if collapsed else ("broken" if hp <= 0 else ("critical" if maximum > 0 and fraction < CRITICAL_FRACTION else "ok"))
			wedges.append(status)
			detail.append({"ring": ring, "wedge": wedge, "status": status, "hp": hp, "max_hp": maximum, "health_fraction": fraction, "broken": status in ["broken", "collapsed"], "brownout": brownout, "relay_down": not collapsed and not relay_active, "lights_powered": not collapsed and hp > 0 and not brownout})
		result.append({"ring": ring, "collapsed": collapsed, "wedges": wedges, "wedge_states": detail, "relay_active": relay_active, "relay_down": not collapsed and not relay_active, "brownout": brownout})
	return result

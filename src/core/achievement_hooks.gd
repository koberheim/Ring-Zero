class_name AchievementHooks
extends RefCounted
## Stable platform-neutral IDs. A Steam adapter subscribes after stats are ready.
signal achievement_requested(id: String)
const IDS := ["FIRST_WATCH","MACHINE_BREAKER","OUTER_FRONTIER","POWER_RESTORED","CONTAINMENT","TRIAL_BY_FIRE"]
var requested := {}

static func earned(summary: Dictionary, mutators: Array = []) -> Array[String]:
	var result: Array[String] = []
	if summary.get("outcome") not in ["victory","defeat"]: return result
	if summary.get("elapsed_seconds",0) >= 300: result.append("FIRST_WATCH")
	if summary.get("kills",0) >= 250: result.append("MACHINE_BREAKER")
	if summary.get("highest_ring",0) >= 6: result.append("OUTER_FRONTIER")
	if summary.get("relay_rebuilds",0) >= 1: result.append("POWER_RESTORED")
	if summary.get("outcome") == "victory":
		result.append("CONTAINMENT")
		if mutators.size() == 3: result.append("TRIAL_BY_FIRE")
	return result

func replay_saved(ids: Array) -> void:
	for id in ids:
		if id in IDS and not requested.has(id):
			requested[id] = true
			achievement_requested.emit(id)

extends RefCounted
## Presentation-only admission and voice arbitration. Never touches simulation RNG.

const VOICE_LIMIT := 24
const RESERVED_CRITICAL := 4
const CRITICAL_PRIORITY := 90
const PAN_LIMIT := 0.85

var active: Array[Dictionary] = []
var cooldown_until := {}
var rng := RandomNumberGenerator.new()
var last_variant := {}
var rejected := {"unknown": 0, "missing": 0, "cooldown": 0, "capacity": 0, "paused": 0}

func _init() -> void:
	rng.randomize()
	for index in VOICE_LIMIT:
		active.append({"until": 0.0, "priority": -1, "event": "", "bus": "SFX"})

func reset() -> void:
	cooldown_until.clear()
	for voice in active:
		voice.until = 0.0
		voice.priority = -1
		voice.event = ""

func select_variant(event_id: String, count: int) -> int:
	if count <= 1: return 0
	var previous: int = last_variant.get(event_id, -1)
	var selected := rng.randi_range(0, count - 2 if previous >= 0 else count - 1)
	if previous >= 0 and selected >= previous: selected += 1
	last_variant[event_id] = selected
	return selected

func reserve(event_id: String, cue: Dictionary, now: float, duration: float, paused: bool) -> int:
	var bus: String = cue.get("bus", "SFX")
	if paused and bus != "UI":
		rejected.paused += 1
		return -1
	if now < float(cooldown_until.get(event_id, 0.0)):
		rejected.cooldown += 1
		return -1
	var priority: int = cue.get("priority", 30)
	var limit := VOICE_LIMIT if priority >= CRITICAL_PRIORITY else VOICE_LIMIT - RESERVED_CRITICAL
	var selected := -1
	var lowest_priority := priority
	var oldest := INF
	for index in limit:
		var voice := active[index]
		if float(voice.until) <= now:
			selected = index
			break
		if int(voice.priority) < lowest_priority or (selected >= 0 and int(voice.priority) == lowest_priority and float(voice.until) < oldest):
			selected = index
			lowest_priority = int(voice.priority)
			oldest = float(voice.until)
	if selected < 0:
		rejected.capacity += 1
		return -1
	active[selected] = {"until": now + maxf(duration, 0.01), "priority": priority, "event": event_id, "bus": bus}
	cooldown_until[event_id] = now + float(cue.get("cooldown_seconds", 0.0))
	return selected

func release(index: int) -> void:
	active[index].until = 0.0
	active[index].priority = -1

static func screen_pan(value: float) -> float:
	return clampf(value, -1.0, 1.0) * PAN_LIMIT if is_finite(value) else 0.0

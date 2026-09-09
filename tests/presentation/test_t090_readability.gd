extends SceneTree
## Behavior-level tests of pure projections. Native art and timed human gates
## deliberately remain separate from these logical checks.
const Lod = preload("res://src/presentation/readability/swarm_lod.gd")
const Status = preload("res://src/presentation/readability/fortress_status.gd")
const Radar = preload("res://src/presentation/readability/integrity_layout.gd")
var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/machines/presentation_v3_v2/metadata.json"))
	var classes: Dictionary = metadata.classes
	var lod := Lod.new()
	check(lod.update_mode(Transform2D(0, Vector2(0.50, 0.50), 0, Vector2.ZERO)), "Enter strategic mass at physical threshold")
	for scale in [0.501, 0.55, 0.619, 0.58, 0.501]:
		check(lod.update_mode(Transform2D(0, Vector2.ONE * scale, 0, Vector2.ZERO)), "Stay in mass mode through hysteresis interval")
	check(not lod.update_mode(Transform2D(0, Vector2.ONE * 0.62, 0, Vector2.ZERO)), "Leave mass at separate threshold")
	check(not lod.update_mode(Transform2D(0, Vector2.ONE * 0.55, 0, Vector2.ZERO)), "Do not toggle back in hysteresis interval")
	for kind in classes:
		var entry: Dictionary = classes[kind]
		for canvas_scale in [0.75, 1.0, 1.3, 1.5]:
			for zoom in [0.05, 0.273, 0.41, 0.85, 4.0]:
				for bearing in 12:
					var transform := Transform2D(0.37, Vector2(zoom * canvas_scale, zoom * canvas_scale * 0.9396926), 0.10, Vector2(312, 91))
					var width := Lod.canvas_world_size(entry, transform)
					var extent := width * float(entry.min_occupied_extent_fraction)
					# An occupied axis with this span exists by F's measured bound.
					# Any axis direction must still occupy >= floor after transform.
					var axis := Vector2.from_angle(float(bearing) * TAU / 12.0) * extent
					var physical_axis := transform.basis_xform(axis)
					check(maxf(absf(physical_axis.x), absf(physical_axis.y)) + 0.0001 >= float(entry.physical_floor_px), "%s occupied floor includes outer scale, tilt, rotation and shear" % kind)
		check(Lod.frame_for(entry, 0.5, true) == 0, "Reduced motion freezes local mechanism")
		check(Lod.frame_for(entry, float(entry.period_seconds), false) == 0, "Atlas loop wraps at period")
		check(Lod.frame_for(entry, float(entry.period_seconds) * 0.5, false) == 4, "Midpoint selects frame four")
		check(Lod.frame_rect(entry, 4).position.y == float(entry.frame_size[1]), "Frame region stays aligned across map channels")
	_test_projection(lod, classes)
	_test_status_and_radar()
	print("T090 readability preparation: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

func _test_projection(lod: RefCounted, classes: Dictionary) -> void:
	var targets: Array[Dictionary] = []
	var points := PackedVector2Array()
	for index in 1000:
		targets.append({"id": index, "kind": "normal", "hp": 10.0})
		points.append(Vector2(float(index % 40) - 20, -200.0 - float(index / 40)))
	for kind in classes:
		targets.append({"id": targets.size(), "kind": kind, "hp": 10.0})
		points.append(Vector2(0, 180))
	targets.append({"id": 2001, "kind": "tunneler", "hp": 10.0, "phase": "burrowing"})
	points.append(Vector2(0, 180))
	targets.append({"id": 2002, "kind": "normal", "hp": 0.0})
	points.append(Vector2(0, 180))
	targets.append({"id": 2003, "kind": "normal", "hp": 10.0})
	points.append(Vector2(20000, 180))
	var before := targets.duplicate(true)
	var transform := Transform2D(0, Vector2(0.41, 0.385), 0, Vector2(960, 540))
	var projection: Dictionary = lod.project(targets, points, transform, Rect2(0, 0, 1920, 1080), classes)
	check(projection.standards.size() == 1000, "Stress projection keeps every living visible standard")
	check(projection.elites.size() == 6, "Six elite classes retained individually; burrowing excluded")
	check(projection.bearing_counts[11] == 1000 and projection.bearing_counts[5] == 6, "Authoritative north/south bearing counts exclude dead, burrowing and offscreen actors")
	check(Lod.dominant_bearings(projection.bearing_counts) == PackedInt32Array([12]), "Dominant bearing reports actual visible count")
	check(Lod.dominant_bearings(PackedInt32Array([2, 2, 0])) == PackedInt32Array([1, 2]), "Ties are represented without invented dominant direction")
	check(Lod.dominant_bearings(PackedInt32Array([0, 0, 0])).is_empty(), "Empty field has no threat direction")
	var batched := 0
	for batch in projection.batches:
		check(batch.x == batched and batch.y <= Lod.BATCH_SIZE, "Bounded batches cover contiguous actor indices")
		batched += batch.y
	check(batched == 1000, "Batch allocation never behaves as a shipping cap")
	var counted := 0
	for bin in projection.bins: counted += int(bin.count)
	check(counted == 1000, "Density bins conserve exact standard count")
	transform.origin += Vector2(30, 25)
	var panned: Dictionary = lod.project(targets, points, transform, Rect2(0, 0, 1920, 1080), classes)
	check(panned.bins == projection.bins and panned.bearing_counts == projection.bearing_counts, "Pan does not move world-anchored bins or bearing")
	check(targets == before, "Projection never mutates actor records")
	var collapsed_transform := Transform2D(0, Vector2.ZERO, 0, Vector2.ZERO)
	check(not lod.project(targets, points, collapsed_transform, Rect2(0, 0, 1920, 1080), classes).valid_transform, "Zero-size viewport rejected without nonfinite sizes")

func _test_status_and_radar() -> void:
	var state := {"rings": {}}
	for ring in range(1, 13):
		var record := {"wedges": {}, "relay": {"active": true}, "relay_hp": 100.0, "relay_max_hp": 100.0}
		for wedge in range(1, 13): record.wedges[wedge] = {"hp": 100.0, "max_hp": 100.0}
		state.rings[ring] = record
	state.rings[2].wedges[3].hp = 24.0
	state.rings[3].wedges[9].hp = 0.0
	state.rings[4].relay_hp = 0.0
	state.rings[6].wedges[12].max_hp = 1000.0
	var before: Dictionary = state.duplicate(true)
	var records := Status.records(state)
	check(records[1].wedges[2] == "critical", "Critical uses actual wedge fraction")
	check(records[2].wedges[8] == "broken", "Broken has explicit shape status")
	check(records[3].relay_down and records[3].brownout, "Dead relay includes own brownout")
	check(records[4].relay_active and records[4].brownout, "Intact downstream relay is distinct from relay loss")
	check(not records[2].brownout and records[5].wedges[11] == "critical", "Chain and authoritative nonstandard max HP remain faithful")
	check(not records[3].wedge_states[0].lights_powered, "Disconnected lamps are not presented as healthy power")
	check(state == before, "Status projection does not mutate authoritative state")
	state.rings[2].wedges[3].hp = 100.0
	state.rings[4].relay_hp = 100.0
	var repaired := Status.records(state)
	check(repaired[1].wedges[2] == "ok" and not repaired[4].brownout, "Fresh projection sees repair and reconnect immediately")
	check(records[1].wedges[2] == "critical", "Previous snapshot does not alias mutable state")
	state.rings[7].collapsed = true
	state.rings[7].relay = {}
	var collapsed := Status.records(state)
	check(collapsed[6].wedges[0] == "collapsed" and not collapsed[6].relay_down, "Total loss is distinct from isolated relay loss")
	for scale in [0.75, 1.0, 1.15, 1.3, 1.5]:
		var transform := Transform2D(0, Vector2.ONE * scale, 0, Vector2.ZERO)
		for count in [1, 6, 12]:
			var size := Radar.minimum_size(count, transform)
			var shape := Radar.geometry(size, count)
			check(float(shape.band) * scale - Radar.SEPARATOR_PIXELS >= Radar.MIN_BAND_PIXELS, "Every painted band retains six physical pixels after separator")
			var subset: Array[Dictionary] = []
			for index in count: subset.append(records[index])
			for index in count:
				for wedge in range(1, 13):
					check(Radar.hit(Radar.focus_point(index, wedge, shape), shape, subset) == Vector2i(index + 1, wedge), "Radar focus and click share exact ring/bearing after resize")
			check(Radar.hit(shape.center, shape, subset) == Vector2i.ZERO, "Core focuses without a false wedge")
			check(Radar.hit(Vector2.ZERO, shape, subset) == Vector2i(-1, -1), "Outside instrument does not claim a wedge")
	for pair in [[0.0, 12], [14.999, 12], [15.001, 1], [344.999, 11], [345.001, 12], [90.0, 3], [180.0, 6], [270.0, 9]]:
		var angle := deg_to_rad(float(pair[0]))
		check(Lod.bearing_for(Vector2(sin(angle), -cos(angle))) == pair[1], "Clock-face seam agrees with existing polar grid")

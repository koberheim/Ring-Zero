class_name EntityPool
extends RefCounted
## Reusable slots with lifetime IDs. Live payload references expire on release.
## active_ids() is a snapshot sorted by increasing lifetime ID.

var capacity: int
var allocated_record_count: int:
	get:
		return _records.size()

var _records: Array[Dictionary] = []
var _free_slots: Array[int] = []
var _id_to_slot: Dictionary = {}
var _next_id: int = 0
var _ids_exhausted: bool = false

func _init(requested_capacity: int) -> void:
	if requested_capacity < 0:
		push_error("EntityPool capacity must be nonnegative; using zero.")
	capacity = maxi(0, requested_capacity)
	for index in range(capacity):
		_records.append({})
		_free_slots.append(capacity - index - 1)

func spawn(payload: Dictionary) -> int:
	if _free_slots.is_empty():
		return -1
	if _ids_exhausted:
		push_error("EntityPool lifetime ID space exhausted.")
		return -1
	var slot: int = _free_slots.pop_back()
	var id := _next_id
	if _next_id == 9223372036854775807:
		_ids_exhausted = true
	else:
		_next_id += 1
	_records[slot].assign(payload)
	_id_to_slot[id] = slot
	return id

func release(id: int) -> bool:
	if not _id_to_slot.has(id):
		return false
	var slot: int = _id_to_slot[id]
	_records[slot].clear()
	_id_to_slot.erase(id)
	_free_slots.append(slot)
	return true

func contains(id: int) -> bool:
	return _id_to_slot.has(id)

func payload_for(id: int) -> Dictionary:
	if not _id_to_slot.has(id):
		return {}
	return _records[_id_to_slot[id]]

func active_ids() -> PackedInt64Array:
	var result := PackedInt64Array(_id_to_slot.keys())
	result.sort()
	return result

func active_count() -> int:
	return _id_to_slot.size()

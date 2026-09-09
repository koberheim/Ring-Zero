extends RefCounted
## Read-only run presentation memory. The host supplies observations and pixels.
## No simulation, reward, profile or filesystem access belongs in this helper.
const MAX_SAMPLES := 256
const SAMPLE_SECONDS := 1.0 # Provisional chart cadence; radius changes are immediate.
const MAX_IMAGE_PIXELS := 3840 * 2160
const MAX_ID_CHARS := 256
var _epoch := 0
var _sequence := 0
var _run_id := ""
var _practice := false
var _outcome := ""
var _history: Array[Dictionary] = []
var _latest: Dictionary = {}
var _peak: Dictionary = {}
var _image_identity: Dictionary = {}
var _image: Image

func reset(run_id: String, practice: bool = false) -> bool:
	if run_id.is_empty() or run_id.length() > MAX_ID_CHARS: return false
	_epoch += 1
	_sequence = 0
	_run_id = run_id
	_practice = practice
	_outcome = ""
	_history.clear()
	_latest.clear()
	_peak.clear()
	_image_identity.clear()
	_image = null
	return true

func observe(seconds: float, radius: int, state_id: String) -> bool:
	if _run_id.is_empty() or not _outcome.is_empty() or not is_finite(seconds) or seconds < 0 or radius < 0 or state_id.is_empty() or state_id.length() > MAX_ID_CHARS: return false
	if not _latest.is_empty() and seconds < float(_latest.seconds): return false
	_sequence += 1
	_latest = {"epoch":_epoch,"sequence":_sequence,"seconds":seconds,"radius":radius,"state_id":state_id}
	if _peak.is_empty() or radius > int(_peak.radius):
		_peak = _latest.duplicate()
		_image = null
		_image_identity.clear()
	if _history.is_empty() or radius != int(_history[-1].radius) or seconds-float(_history[-1].seconds) >= SAMPLE_SECONDS:
		_history.append(_latest.duplicate())
		_reduce(_history,MAX_SAMPLES-1)
	return true

func capture_ticket() -> Dictionary:
	if _latest.is_empty() or _image != null or int(_latest.radius) != int(_peak.radius): return {}
	return _latest.duplicate()

func supply_capture(ticket: Dictionary, captured_state: Dictionary, pixels: Image) -> bool:
	# captured_state must describe the frame actually rendered, not request time.
	# Reject delayed captures after a tick/state change or after reset/new peak.
	if ticket.is_empty() or ticket != _latest or captured_state != ticket or int(ticket.get("radius",-1)) != int(_peak.get("radius",-2)): return false
	if pixels == null or pixels.is_empty(): return false
	if pixels.has_mipmaps(): return false
	if pixels.get_width() > 4096 or pixels.get_height() > 4096 or pixels.get_width()*pixels.get_height() > MAX_IMAGE_PIXELS: return false
	if pixels.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return false
	_image = pixels.duplicate() as Image
	_image_identity = captured_state.duplicate()
	return true

func finish(outcome: String) -> bool:
	if outcome not in ["victory","defeat","abandoned","error","practice"]: return false
	if not _outcome.is_empty(): return _outcome == outcome
	_outcome = outcome
	return true

func snapshot() -> Dictionary:
	var samples: Array[Dictionary] = _history.duplicate(true)
	if not _latest.is_empty() and (samples.is_empty() or samples[-1] != _latest): samples.append(_latest.duplicate())
	_reduce(samples,MAX_SAMPLES)
	return {"run_id":_run_id,"practice":_practice,"outcome":_outcome,"has_data":not _latest.is_empty(),"samples":samples,"latest":_latest.duplicate(),"peak":_peak.duplicate(),"has_peak_image":_image != null,"image_identity":_image_identity.duplicate(),"history_reduced":_sequence > samples.size()}

func peak_image() -> Image:
	# Callers cannot mutate retained pixels through a returned reference.
	return _image.duplicate() as Image if _image != null else null

func _reduce(samples: Array[Dictionary], limit: int) -> void:
	while samples.size() > limit:
		var remove_at := -1
		var smallest := INF
		for index in range(1,samples.size()-1):
			if samples[index] == _peak: continue
			var a: Dictionary = samples[index-1]
			var b: Dictionary = samples[index]
			var c: Dictionary = samples[index+1]
			var area := absf((float(b.seconds)-float(a.seconds))*float(int(c.radius)-int(a.radius))-(float(c.seconds)-float(a.seconds))*float(int(b.radius)-int(a.radius)))
			if area < smallest:
				smallest = area
				remove_at = index
		if remove_at < 0: return
		# Retain actual first/latest observations and exact observed global peak.
		# Reduced chart segments never invent interpolated sample identities.
		samples.remove_at(remove_at)

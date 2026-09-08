class_name FixedStepClock
extends RefCounted
## Accumulates fractional ticks; tolerance is 1e-12 of a tick near a boundary.
## A tolerated rounding deficit is clamped to zero, never carried as debt.

const BOUNDARY_TOLERANCE := 1.0e-12
var paused: bool = false
var tick_count: int = 0
var _tick_hz: float = 0.0
var _step_seconds: float = 0.0
var _remainder: float = 0.0
var _on_tick: Callable
var _valid: bool = false

func _init(tick_hz: float, on_tick: Callable) -> void:
	if not is_finite(tick_hz) or tick_hz <= 0.0 or not is_finite(1.0 / tick_hz):
		push_error("FixedStepClock requires a finite positive rate with a finite step.")
		return
	if not on_tick.is_valid():
		push_error("FixedStepClock requires a valid callback.")
		return
	_tick_hz = tick_hz
	_step_seconds = 1.0 / tick_hz
	_on_tick = on_tick
	_valid = true

func advance(delta_seconds: float) -> int:
	if not is_finite(delta_seconds) or delta_seconds < 0.0:
		push_error("FixedStepClock delta must be finite and nonnegative.")
		return 0
	if not _valid or paused:
		return 0
	_remainder += delta_seconds
	var completed := 0
	var tolerance := _step_seconds * BOUNDARY_TOLERANCE
	while _remainder >= _step_seconds or _step_seconds - _remainder <= tolerance:
		_remainder = maxf(0.0, _remainder - _step_seconds)
		tick_count += 1
		completed += 1
		_on_tick.call(_step_seconds)
		if paused:
			# A callback pause takes effect at this tick boundary. Remaining
			# wall time in this advance belongs to the paused interval.
			_remainder = 0.0
			break
	return completed

func elapsed_seconds() -> float:
	return tick_count / _tick_hz if _valid else 0.0

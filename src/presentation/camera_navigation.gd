extends Node
## Continuous map navigation in screen space; never feeds build commands.
var host: Control
var held := {}
const DIRECTIONS := {"Map up": Vector2.UP, "Map left": Vector2.LEFT, "Map down": Vector2.DOWN, "Map right": Vector2.RIGHT}
const ARROWS := {KEY_UP: Vector2.UP, KEY_LEFT: Vector2.LEFT, KEY_DOWN: Vector2.DOWN, KEY_RIGHT: Vector2.RIGHT}
const SCREEN_SPEED := 900.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().focus_exited.connect(func(): held.clear())

func _active() -> bool:
	if host.live == null or host.state not in ["playing", "tutorial"] or get_tree().paused: return false
	if host.live.menu_open or not host.rebinding.is_empty(): return false
	var focus: Control = host.stage.gui_get_focus_owner()
	return not (focus is LineEdit or focus is TextEdit)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not event.pressed:
		held.erase(key)
		return
	if not _active() or event.ctrl_pressed or event.alt_pressed or event.meta_pressed: return
	if _key_direction(key) != Vector2.ZERO:
		held[key] = true
		get_viewport().set_input_as_handled()

func _key_direction(key: int) -> Vector2:
	for action in DIRECTIONS:
		if PCSettings.bindings[action] == key: return DIRECTIONS[action]
	# Arrow aliases remain available unless the player assigns one to a tool.
	return ARROWS.get(key, Vector2.ZERO) if key not in PCSettings.bindings.values() else Vector2.ZERO

func direction() -> Vector2:
	var result := Vector2.ZERO
	for key in held: result += _key_direction(key)
	return result.limit_length()

func _process(delta: float) -> void:
	if not _active():
		held.clear()
		return
	var movement := direction()
	if movement.is_zero_approx(): return
	var viewport_scale: float = float(host.stage.size.x) / 2560.0
	host.live.camera.position += movement * SCREEN_SPEED * viewport_scale * minf(delta, 0.05) / host.live.camera.zoom
	host.live.camera.force_update_scroll()
	host.live.queue_redraw()

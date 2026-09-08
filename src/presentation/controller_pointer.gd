extends Node
## Virtual pointer shares the real GUI/world event path, including letterboxing.
var host: Control
var point := Vector2(720,405)
var axes := Vector4.ZERO
var pointer: Label
var device := -1
var tool_index := 0
var scroll_clock := 0.0
var scroll_direction := 0
var zoom_axes := Vector2.ZERO
const TOOLS := ["Flak","Mass Driver","EMP Node","Lance Emitter","Point Defense","Expand","Wall","Armor","Repair Node","Repair","Reclaim","Relay","Debris","Tractor","Occlusion"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pointer = Label.new()
	pointer.text = "+"
	pointer.add_theme_font_size_override("font_size",28)
	pointer.modulate = Color("ffd391")
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer.z_index = 200
	host.shell.add_child(pointer)
	pointer.hide()
	Input.joy_connection_changed.connect(func(id: int, connected: bool):
		if id == device and not connected:
			axes = Vector4.ZERO
			zoom_axes = Vector2.ZERO
			scroll_direction = 0
			pointer.hide()
	)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.device != -8:
		pointer.hide()
	if event is InputEventJoypadMotion:
		device = event.device
		pointer.show()
		var value: float = signf(event.axis_value)*maxf(0,absf(event.axis_value)-0.2)/0.8
		match event.axis:
			JOY_AXIS_LEFT_X: axes.x = value
			JOY_AXIS_LEFT_Y: axes.y = value
			JOY_AXIS_RIGHT_X: axes.z = value
			JOY_AXIS_RIGHT_Y: axes.w = value
			JOY_AXIS_TRIGGER_LEFT:
				zoom_axes.x = maxf(0.0,event.axis_value-0.15)/0.85
			JOY_AXIS_TRIGGER_RIGHT:
				zoom_axes.y = maxf(0.0,event.axis_value-0.15)/0.85
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		if host.state == "controls" and not host.rebinding.is_empty(): return
		device = event.device
		pointer.show()
		var button := PCSettings.pad_button(event.button_index)
		match button:
			JOY_BUTTON_A: _mouse(MOUSE_BUTTON_LEFT,event.pressed)
			JOY_BUTTON_B:
				if event.pressed:
					if host.state in ["playing","tutorial"] and host.live != null and not host.live.menu_open: _mouse(MOUSE_BUTTON_RIGHT,true)
					else: _key("Pause / cancel")
			JOY_BUTTON_START:
				if event.pressed: _key("Pause / cancel")
			JOY_BUTTON_X:
				if event.pressed: _key("EMP Burst")
			JOY_BUTTON_Y:
				if event.pressed: _key("Flare")
			JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER:
				if event.pressed:
					tool_index = posmod(tool_index+(-1 if button == JOY_BUTTON_LEFT_SHOULDER else 1),TOOLS.size())
					# Expansion has a cost; never purchase merely by cycling tools.
					if TOOLS[tool_index] == "Expand": tool_index = posmod(tool_index+(-1 if button == JOY_BUTTON_LEFT_SHOULDER else 1),TOOLS.size())
					_key(TOOLS[tool_index])
			JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN:
				scroll_direction = (-1 if button == JOY_BUTTON_DPAD_UP else 1) if event.pressed else 0
			JOY_BUTTON_BACK:
				if event.pressed: _key("Catalogue")
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not pointer.visible: return
	if not zoom_axes.is_zero_approx(): _zoom(pow(2.0,(zoom_axes.y-zoom_axes.x)*minf(delta,0.05)))
	var movement := Vector2(axes.x,axes.y).limit_length()*650.0*minf(delta,0.05)
	point = (point+movement).clamp(Vector2(2,2),Vector2(1438,808))
	pointer.position = point-Vector2(8,18)
	if movement.length_squared() > 0:
		var event := InputEventMouseMotion.new()
		event.device = -8
		event.position = host.frame.position+point*host.frame.scale
		event.global_position = event.position
		event.relative = movement
		get_viewport().push_input(event)
	if host.live != null and host.state in ["playing","tutorial"] and not host.live.menu_open and not get_tree().paused:
		host.live.camera.position += Vector2(axes.z,axes.w)*450.0*minf(delta,0.05)/host.live.camera.zoom
		host.live.camera.force_update_scroll()
		host.live.queue_redraw()
	scroll_clock -= delta
	if scroll_direction != 0 and scroll_clock <= 0:
		scroll_clock = 0.12
		_mouse(MOUSE_BUTTON_WHEEL_UP if scroll_direction < 0 else MOUSE_BUTTON_WHEEL_DOWN,true)

func _mouse(button: MouseButton, pressed: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.device = -8
	motion.position = host.frame.position+point*host.frame.scale
	get_viewport().push_input(motion)
	var event := InputEventMouseButton.new()
	event.device = -8
	event.position = motion.position
	event.global_position = event.position
	event.button_index = button
	event.pressed = pressed
	get_viewport().push_input(event)

func _key(action: String) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = PCSettings.bindings[action]
	event.pressed = true
	get_viewport().push_input(event)

func _zoom(factor: float) -> void:
	if host.live != null and host.state in ["playing","tutorial"] and not host.live.menu_open:
		host.live._set_zoom(clampf(host.live.camera.zoom.x*factor,0.05,4.0))
		host.live.queue_redraw()

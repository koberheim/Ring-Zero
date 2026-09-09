extends SceneTree

class TestHost extends Control:
	var live: Node2D
	var stage: SubViewport
	var state := "playing"
	var rebinding := ""
	var shell := Control.new()
	var frame := Control.new()

class TestWorld extends Node2D:
	var menu_open := false
	var camera := Camera2D.new()

var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func key(navigation: Node, code: int, pressed := true, modifier := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.ctrl_pressed = modifier
	navigation._input(event)

func _run() -> void:
	var path := "res://.godot/navigation-test-%d.cfg" % Time.get_ticks_usec()
	PCSettings.load_settings(path)
	check(PCSettings.logical_key(KEY_W) == 0 and PCSettings.logical_key(KEY_A) == 0 and PCSettings.logical_key(KEY_S) == 0 and PCSettings.logical_key(KEY_D) == 0, "WASD cannot arm old build tools")
	check(PCSettings.logical_key(KEY_H) == KEY_W and PCSettings.logical_key(KEY_C) == KEY_A and PCSettings.logical_key(KEY_V) == KEY_S and PCSettings.logical_key(KEY_B) == KEY_D, "New tool bindings preserve the command protocol")
	var legacy := PCSettings.LOGICAL_KEYS.duplicate()
	var config := ConfigFile.new()
	config.set_value("input", "bindings", legacy)
	config.save(path)
	PCSettings.load_settings(path)
	check(PCSettings.bindings == PCSettings.DEFAULT_KEYS, "Old default configuration migrates to WASD navigation")
	legacy["Flak"] = KEY_H
	config.set_value("input", "bindings", legacy)
	config.save(path)
	PCSettings.load_settings(path)
	check(PCSettings.bindings["Flak"] == KEY_H and PCSettings.bindings["Wall"] == KEY_6, "Migration preserves custom bindings and relocates conflicts")
	check(PCSettings._valid_keyboard_map(PCSettings.bindings, PCSettings.DEFAULT_KEYS), "Migration leaves every action reachable with a unique key")
	check(PCSettings.save_settings() == OK, "Migrated bindings save")
	var migrated := PCSettings.bindings.duplicate()
	PCSettings.load_settings(path)
	check(PCSettings.bindings == migrated, "Versioned settings reload without re-migrating")
	PCSettings.bindings = PCSettings.DEFAULT_KEYS.duplicate()
	var host := TestHost.new()
	host.stage = SubViewport.new()
	host.stage.size = Vector2i(2560, 1440)
	host.add_child(host.stage)
	host.live = TestWorld.new()
	host.live.add_child(host.live.camera)
	host.stage.add_child(host.live)
	root.add_child(host)
	var navigation: Node = load("res://src/presentation/camera_navigation.gd").new()
	navigation.host = host
	host.add_child(navigation)
	navigation.set_process(false)
	key(navigation, KEY_W)
	navigation._process(0.025)
	check(host.live.camera.position.is_equal_approx(Vector2(0, -22.5)), "Held W moves up continuously using elapsed time")
	check(navigation.direction() == Vector2.UP, "Held key remains active between events")
	key(navigation, KEY_D)
	check(is_equal_approx(navigation.direction().length(), 1.0), "Diagonal speed does not exceed cardinal speed")
	key(navigation, KEY_W, false)
	key(navigation, KEY_D, false)
	check(navigation.direction().is_zero_approx(), "Releasing movement keys stops movement")
	host.live.camera.position = Vector2.ZERO
	host.live.camera.zoom = Vector2(2, 1)
	key(navigation, KEY_D)
	navigation._process(0.025)
	check(host.live.camera.position.is_equal_approx(Vector2(11.25, 0)), "Panning is corrected for camera zoom")
	host.live.menu_open = true
	navigation._process(0.025)
	check(navigation.held.is_empty(), "Opening a menu cancels held movement")
	host.live.menu_open = false
	key(navigation, KEY_D, true, true)
	check(navigation.held.is_empty(), "Modified shortcuts cannot pan the map")
	host.state = "controls"
	key(navigation, KEY_D)
	check(navigation.held.is_empty(), "Settings and remapping pages cannot move the world")
	host.state = "playing"
	key(navigation, KEY_D)
	root.focus_exited.emit()
	check(navigation.held.is_empty(), "Focus loss clears held keys")
	key(navigation, KEY_UP)
	check(navigation.direction() == Vector2.UP, "Unassigned arrows provide alternate navigation")
	key(navigation, KEY_UP, false)
	check(PCSettings.rebind("Flak", KEY_UP) == OK, "An arrow can be assigned to a tool")
	key(navigation, KEY_UP)
	check(navigation.held.is_empty(), "An assigned arrow stops its implicit navigation alias")
	check(PCSettings.rebind("Map up", KEY_I) == OK, "Map actions are remappable")
	key(navigation, KEY_W)
	check(navigation.held.is_empty(), "The former movement key no longer pans after rebinding")
	key(navigation, KEY_I)
	check(navigation.direction() == Vector2.UP, "The new movement key pans")
	paused = true
	navigation._process(0.025)
	check(navigation.held.is_empty(), "Pausing cancels held navigation")
	paused = false
	host.add_child(host.frame)
	host.stage.add_child(host.shell)
	var controller: Node = load("res://src/presentation/controller_pointer.gd").new()
	controller.host = host
	host.add_child(controller)
	controller.set_process(false)
	check(controller.point == Vector2(1280, 720), "Controller pointer starts at the native 2K viewport center")
	controller.pointer.show()
	controller.point = Vector2(5000, 5000)
	controller._process(0.0)
	check(controller.point == Vector2(2558, 1438), "Controller pointer reaches and clamps to the native 2K viewport edge")
	controller.axes = Vector4.ONE
	controller.zoom_axes = Vector2.ONE
	controller.scroll_direction = 1
	root.focus_exited.emit()
	check(controller.axes == Vector4.ZERO and controller.zoom_axes == Vector2.ZERO and controller.scroll_direction == 0, "Focus loss clears all controller motion")
	controller.device = 42
	controller.axes = Vector4.ONE
	controller.zoom_axes = Vector2.ONE
	controller.scroll_direction = 1
	Input.joy_connection_changed.emit(42, false)
	check(controller.axes == Vector4.ZERO and controller.zoom_axes == Vector2.ZERO and controller.scroll_direction == 0, "Controller disconnect clears all motion")
	host.queue_free()
	await process_frame
	PCSettings.bindings = PCSettings.DEFAULT_KEYS.duplicate()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PC navigation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

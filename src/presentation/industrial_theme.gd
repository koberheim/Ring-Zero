extends RefCounted
## Local, redistributable interface resources. No world-art dependency.
const HOUSING := Color("15191d")
const RECESS := Color("242c32")
const STEEL := Color("8f9da6")
const INK := Color("edf1ef")
const AMBER := Color("f2b85b")
const FAULT := Color("ff8173")

static func box(color: Color, border: Color = STEEL, inset: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(inset)
	style.corner_radius_top_left = 2
	style.corner_radius_bottom_right = 2
	return style

static func make(ui_scale: float = 1.0) -> Theme:
	var result := Theme.new()
	result.default_font = load("res://assets/ui/fonts/barlow/Barlow-Regular.ttf")
	result.default_font_size = roundi(18 * ui_scale)
	var strong: Font = load("res://assets/ui/fonts/barlow/Barlow-SemiBold.ttf")
	for type in ["Label", "Button", "CheckButton", "OptionButton", "TabContainer", "LineEdit", "RichTextLabel"]:
		result.set_color("font_color", type, INK)
	result.set_font("font", "Button", strong)
	result.set_stylebox("panel", "PanelContainer", box(HOUSING, STEEL.darkened(0.5), 12))
	result.set_stylebox("normal", "Button", box(RECESS, STEEL.darkened(0.45), 8))
	result.set_stylebox("hover", "Button", box(RECESS.lightened(0.1), AMBER, 8))
	result.set_stylebox("pressed", "Button", box(HOUSING, AMBER, 8))
	result.set_stylebox("disabled", "Button", box(HOUSING, STEEL.darkened(0.6), 8))
	var focus := box(Color.TRANSPARENT, AMBER, 8)
	focus.set_border_width_all(2)
	result.set_stylebox("focus", "Button", focus)
	result.set_color("font_disabled_color", "Button", STEEL)
	result.set_stylebox("panel", "TabContainer", box(HOUSING, STEEL.darkened(0.5), 4))
	for state in ["tab_selected", "tab_unselected", "tab_hovered", "tab_disabled"]:
		result.set_stylebox(state, "TabContainer", box(RECESS if state == "tab_selected" else HOUSING, AMBER if state == "tab_selected" else STEEL.darkened(0.6), 6))
	result.set_stylebox("normal", "LineEdit", box(RECESS))
	result.set_stylebox("focus", "LineEdit", focus)
	result.set_constant("separation", "VBoxContainer", 8)
	result.set_constant("separation", "HBoxContainer", 12)
	return result

static func heading(label: Label, size: int = 32) -> void:
	label.add_theme_font_override("font", load("res://assets/ui/fonts/barlow/BarlowSemiCondensed-SemiBold.ttf"))
	label.add_theme_font_size_override("font_size", size)

extends RefCounted
## Native 1440p instrument typography and anodised metal control surfaces.
const HOUSING := Color("111b25")
const RECESS := Color("172631")
const STEEL := Color("839ba8")
const INK := Color("f2e6cc")
const AMBER := Color("d5ac6e")
const FAULT := Color("f58b72")
const CYAN := Color("91cfdf")

# T-086 provisional native-pixel values: 104 x 36 selector, 16 px icon gap,
# 12/6 px row insets and a 3 px focus keyline. Native 1080p fit is 0.75x.
# These recessed switch rows deliberately have no raised-button shadow.
static func switch_surface(fill: Color, edge: Color, focused: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(3 if focused else 1)
	style.set_content_margin_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	return style

static func apply_switches(result: Theme) -> void:
	for icon_name in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
		var texture: Texture2D = load("res://assets/ui/controls/switch_"+icon_name+".svg")
		result.set_icon(icon_name, "CheckButton", texture)
		result.set_icon(icon_name+"_mirrored", "CheckButton", texture)
	result.set_constant("h_separation", "CheckButton", 16)
	result.set_constant("check_v_offset", "CheckButton", 0)
	result.set_stylebox("normal", "CheckButton", switch_surface(Color("101d27"), Color("334954")))
	result.set_stylebox("hover", "CheckButton", switch_surface(Color("203441"), STEEL))
	result.set_stylebox("pressed", "CheckButton", switch_surface(Color("242820"), Color("806c49")))
	result.set_stylebox("hover_pressed", "CheckButton", switch_surface(Color("34372a"), AMBER))
	result.set_stylebox("disabled", "CheckButton", switch_surface(Color("101922"), Color("293a45")))
	result.set_stylebox("focus", "CheckButton", switch_surface(Color.TRANSPARENT, INK, true))
	for state in ["font_color", "font_pressed_color", "font_hover_pressed_color"]:
		result.set_color(state, "CheckButton", INK)
	result.set_color("font_hover_color", "CheckButton", Color.WHITE)
	result.set_color("font_focus_color", "CheckButton", INK)
	result.set_color("font_disabled_color", "CheckButton", Color("94a2a9"))
	result.set_icon("arrow", "OptionButton", load("res://assets/ui/controls/select_arrow.svg"))
	result.set_constant("arrow_margin", "OptionButton", 16)
	result.set_constant("modulate_arrow", "OptionButton", 1)

static func box(color: Color, border: Color = STEEL, inset: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_content_margin_all(inset)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0,0,0,0.38)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0,5)
	return style

static func make(ui_scale: float = 1.0) -> Theme:
	var result := Theme.new()
	result.default_font = load("res://assets/ui/fonts/barlow/Barlow-Regular.ttf")
	result.default_font_size = roundi(30 * ui_scale)
	var strong: Font = load("res://assets/ui/fonts/barlow/Barlow-SemiBold.ttf")
	for type in ["Label", "Button", "CheckButton", "CheckBox", "OptionButton", "TabContainer", "LineEdit", "RichTextLabel", "PopupMenu"]:
		result.set_color("font_color", type, INK)
	result.set_font("font", "Button", strong)
	result.set_color("font_color", "Label", INK)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", AMBER)
	result.set_stylebox("panel", "PanelContainer", box(Color("101b25f5"), Color("49606c"), 32))
	for type in ["Button","OptionButton"]:
		result.set_stylebox("normal", type, box(RECESS, Color("405766"), 16))
		result.set_stylebox("hover", type, box(Color("263947"), AMBER, 16))
		result.set_stylebox("pressed", type, box(Color("0a131c"), AMBER, 16))
		result.set_stylebox("disabled", type, box(Color("111922"), Color("293b45"), 16))
		var focus := box(Color.TRANSPARENT, AMBER, 16)
		focus.set_border_width_all(3)
		result.set_stylebox("focus", type, focus)
		result.set_color("font_disabled_color", type, Color("73858e"))
	result.set_stylebox("panel", "PopupMenu", box(HOUSING, AMBER, 16))
	result.set_stylebox("hover", "PopupMenu", box(RECESS, AMBER, 10))
	result.set_constant("v_separation", "PopupMenu", 18)
	result.set_stylebox("panel", "TabContainer", box(Color("0c151dd9"), Color("314b58"), 18))
	for state in ["tab_selected", "tab_unselected", "tab_hovered", "tab_disabled"]:
		result.set_stylebox(state, "TabContainer", box(RECESS if state == "tab_selected" else HOUSING, AMBER if state == "tab_selected" else Color("314b58"), 16))
	result.set_stylebox("normal", "LineEdit", box(RECESS))
	result.set_stylebox("slider", "HSlider", box(Color("263b48"),Color("3d5561"),4))
	result.set_stylebox("grabber_area", "HSlider", box(AMBER,AMBER,4))
	result.set_stylebox("grabber_area_highlight", "HSlider", box(INK,AMBER,4))
	result.set_constant("separation", "VBoxContainer", 20)
	result.set_constant("separation", "HBoxContainer", 24)
	result.set_constant("h_separation", "GridContainer", 24)
	result.set_constant("v_separation", "GridContainer", 16)
	apply_switches(result)
	return result

static func heading(label: Label, size: int = 52) -> void:
	label.add_theme_font_override("font", load("res://assets/ui/fonts/barlow/BarlowSemiCondensed-SemiBold.ttf"))
	label.add_theme_font_size_override("font_size", size)

static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal",box(AMBER,Color("f2d09a"),20))
	button.add_theme_stylebox_override("hover",box(INK,Color.WHITE,20))
	button.add_theme_stylebox_override("pressed",box(Color("b18b51"),INK,20))
	button.add_theme_color_override("font_color",Color("111923"))
	button.add_theme_color_override("font_hover_color",Color("111923"))
	button.add_theme_color_override("font_pressed_color",Color("111923"))


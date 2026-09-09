extends RefCounted
## Native 1440p instrument typography and anodised metal control surfaces.
const Tokens = preload("res://src/presentation/ui_tokens.gd")
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

static func surface(fill: Color, edge: Color, inset: int = 12, raised: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_content_margin_all(inset)
	if raised:
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.corner_radius_top_left = 4
		style.corner_radius_bottom_right = 4
	return style

static func make(ui_scale: float = 1.0, viewport_height: float = 1440.0) -> Theme:
	var result := Theme.new()
	var d := Tokens.density(viewport_height)
	var inset := roundi(12*d)
	result.default_font = Tokens.BODY
	result.default_font_size = Tokens.text("body",ui_scale,viewport_height)
	for type in ["Label","Button","CheckButton","CheckBox","OptionButton","TabBar","TabContainer","LineEdit","RichTextLabel","PopupMenu","TooltipLabel"]:
		result.set_color("font_color",type,INK)
		result.set_color("font_disabled_color",type,Color("94a2a9"))
		result.set_color("font_hover_color",type,Color.WHITE)
		result.set_color("font_focus_color",type,INK)
	result.set_font("font","Button",Tokens.STRONG)
	result.set_stylebox("panel","PanelContainer",surface(HOUSING,Color("49606c"),roundi(24*d)))
	for type in ["Button","OptionButton","CheckBox"]:
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			var fill := RECESS
			var edge := Color("405766")
			if state in ["hover","hover_pressed"]: fill = Color("263947"); edge = AMBER
			if state == "pressed": fill = Color("302b20"); edge = AMBER
			if state == "disabled": fill = Color("111922"); edge = Color("293b45")
			result.set_stylebox(state,type,surface(fill,edge,inset,type == "Button"))
		var focus := surface(Color.TRANSPARENT,INK,inset)
		focus.set_border_width_all(2)
		result.set_stylebox("focus",type,focus)
		result.set_color("font_pressed_color",type,INK)
	result.set_stylebox("panel","PopupMenu",surface(HOUSING,STEEL,inset))
	result.set_stylebox("hover","PopupMenu",surface(RECESS,AMBER,roundi(8*d)))
	result.set_stylebox("separator","PopupMenu",surface(STEEL,STEEL,0))
	result.set_constant("v_separation","PopupMenu",roundi(14*d))
	for type in ["TabBar","TabContainer"]:
		result.set_stylebox("panel",type,surface(Color("101d27"),Color("334954"),inset))
		for state in ["tab_selected","tab_unselected","tab_hovered","tab_disabled","tab_focus"]:
			var style := surface(RECESS if state == "tab_selected" else HOUSING,AMBER if state in ["tab_selected","tab_hovered"] else Color("334954"),roundi(9*d))
			if state == "tab_selected": style.border_width_bottom = 3
			if state == "tab_focus": style.bg_color = Color.TRANSPARENT; style.border_color = INK; style.set_border_width_all(2)
			result.set_stylebox(state,type,style)
		result.set_color("font_selected_color",type,INK)
		result.set_color("font_unselected_color",type,STEEL)
		result.set_color("font_hovered_color",type,Color.WHITE)
	for state in ["normal","read_only","focus"]:
		result.set_stylebox(state,"LineEdit",surface(RECESS,INK if state == "focus" else STEEL,inset))
	result.set_color("caret_color","LineEdit",INK)
	result.set_color("selection_color","LineEdit",Color("49606c"))
	for type in ["HSlider","VSlider","HScrollBar","VScrollBar"]:
		var slider: bool = "Slider" in type
		result.set_stylebox("slider" if slider else "scroll",type,surface(Color("0b141c"),Color("334954"),4))
		for state in (["grabber_area","grabber_area_highlight"] if slider else ["grabber","grabber_highlight","grabber_pressed"]):
			result.set_stylebox(state,type,surface(AMBER if "highlight" in state or "pressed" in state else STEEL,INK,6))
		result.set_stylebox("scroll_focus",type,surface(Color.TRANSPARENT,INK,0))
		if slider:
			for state in ["grabber","grabber_highlight","grabber_disabled"]:
				result.set_icon(state,type,load("res://assets/ui/controls/slider_grip.svg"))
		else:
			for state in ["increment","increment_highlight","increment_pressed","decrement","decrement_highlight","decrement_pressed"]:
				result.set_icon(state,type,load("res://assets/ui/controls/scroll_arrow.svg"))
	result.set_stylebox("background","ProgressBar",surface(Color("0b141c"),Color("334954"),0))
	result.set_stylebox("fill","ProgressBar",surface(CYAN,CYAN,0))
	result.set_stylebox("panel","TooltipPanel",surface(Color("101922"),STEEL,inset))
	result.set_font_size("font_size","TooltipLabel",Tokens.text("caption",ui_scale,viewport_height))
	result.set_stylebox("separator","HSeparator",surface(Color("334954"),Color("334954"),0))
	for type in ["VBoxContainer","HBoxContainer"]: result.set_constant("separation",type,roundi(12*d))
	for axis in ["h","v"]: result.set_constant(axis+"_separation","GridContainer",roundi(12*d))
	for type in ["CheckBox","PopupMenu"]:
		for state in ["checked","unchecked","checked_disabled","unchecked_disabled","radio_checked","radio_unchecked","radio_checked_disabled","radio_unchecked_disabled"]:
			result.set_icon(state,type,load("res://assets/ui/controls/choice_checked.svg" if "unchecked" not in state else "res://assets/ui/controls/choice_unchecked.svg"))
	for type in ["TabBar","TabContainer"]:
		for icon_name in ["increment","increment_highlight","decrement","decrement_highlight","menu","menu_highlight"]:
			result.set_icon(icon_name,type,load("res://assets/ui/controls/scroll_arrow.svg"))
	apply_switches(result)
	return result

static func role(label: Label, role_name: String, scale_value: float, height: float) -> void:
	label.add_theme_font_override("font",Tokens.font(role_name))
	label.add_theme_font_size_override("font_size",Tokens.text(role_name,scale_value,height))

static func heading(label: Label, size: int = 52) -> void:
	label.set_meta("type_role","display" if size >= 140 else ("title" if size >= 70 else "value" if size >= 60 else "heading" if size >= 40 else "caption"))
	label.add_theme_font_override("font", load("res://assets/ui/fonts/barlow/BarlowSemiCondensed-SemiBold.ttf"))
	label.add_theme_font_size_override("font_size", size)

static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal",box(AMBER,Color("f2d09a"),20))
	button.add_theme_stylebox_override("hover",box(INK,Color.WHITE,20))
	button.add_theme_stylebox_override("pressed",box(Color("b18b51"),INK,20))
	button.add_theme_color_override("font_color",Color("111923"))
	button.add_theme_color_override("font_hover_color",Color("111923"))
	button.add_theme_color_override("font_pressed_color",Color("111923"))


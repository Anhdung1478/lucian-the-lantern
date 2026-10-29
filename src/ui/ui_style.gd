class_name UiStyle
extends RefCounted
## Shared look of the menu-style screens: dark navy panels with a gold border
## and buttons that light up gold on hover.

const PANEL_COLOR := Color(0.06, 0.075, 0.1, 0.96)
const BORDER_COLOR := Color(0.79, 0.64, 0.36)
const TITLE_COLOR := Color("ffe9a8")
const TEXT_COLOR := Color("d8dde6")
const DIM_COLOR := Color("9aa3b2")
const GOLD_COLOR := Color("ffcf5a")
const ERROR_COLOR := Color("ff6a5a")
const DISABLED_FONT := Color(0.45, 0.48, 0.55)
## A styled button's soft click, quiet under the game's sounds.
const CLICK_DB := -10.0
## Set on a button once its click is connected, so a restyle adds no second.
const CLICK_META := &"click_sound"


static func panel(color := PANEL_COLOR, border := BORDER_COLOR, border_width := 2, margin := 28.0, radius := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style


static func button_style(state: StringName, selected := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.set_content_margin_all(6)
	match state:
		&"hover":
			style.bg_color = Color(0.12, 0.14, 0.19)
			style.border_color = BORDER_COLOR
		&"pressed":
			style.bg_color = Color(0.2, 0.17, 0.1)
			style.border_color = BORDER_COLOR
		&"disabled":
			style.bg_color = Color(0.07, 0.08, 0.1)
			style.border_color = Color(0.2, 0.22, 0.26)
		_:
			style.bg_color = Color(0.2, 0.17, 0.1) if selected else Color(0.09, 0.105, 0.14)
			style.border_color = BORDER_COLOR if selected else Color(0.36, 0.4, 0.48)
	return style


## Applies the button look and its click. `selected` keeps it lit, e.g. the
## open tab.
static func style_button(button: Button, font_size := 22, selected := false) -> void:
	if not button.has_meta(CLICK_META):
		button.set_meta(CLICK_META, true)
		button.pressed.connect(func() -> void: Sfx.play(&"click", CLICK_DB))
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override(&"font_size", font_size)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, button_style(state, selected))
	button.add_theme_color_override(&"font_color", TITLE_COLOR if selected else TEXT_COLOR)
	button.add_theme_color_override(&"font_hover_color", TITLE_COLOR)
	button.add_theme_color_override(&"font_disabled_color", DISABLED_FONT)


static func label(text: String, font_size := 18, color := TEXT_COLOR) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override(&"font_size", font_size)
	result.add_theme_color_override(&"font_color", color)
	return result

class_name UiStyle
extends RefCounted
## Shared look of the menu-style screens: dark navy panels with a gold border
## and buttons that light up gold on hover. theme() gives the same look to
## Godot's own widgets (sliders, dropdowns, switches, scroll bars).

const PANEL_COLOR := Color(0.06, 0.075, 0.1, 0.96)
const BORDER_COLOR := Color(0.79, 0.64, 0.36)
const TITLE_COLOR := Color("ffe9a8")
const TEXT_COLOR := Color("d8dde6")
const DIM_COLOR := Color("9aa3b2")
const GOLD_COLOR := Color("ffcf5a")
const ERROR_COLOR := Color("ff6a5a")
const DISABLED_FONT := Color(0.45, 0.48, 0.55)
## The lantern's teal: the title's "THE LANTERN" and Senna's light.
const LANTERN_COLOR := Color("8fe3b0")
## A plate's gradient, top to bottom (Plate, MenuCard).
const PLATE_TOP := Color("0b1220")
const PLATE_BOTTOM := Color("0d2328")
## A cell that holds an item, a skill or a spell: its well and its rim.
const CELL_COLOR := Color(0.03, 0.04, 0.06)
const CELL_BORDER := Color(0.36, 0.4, 0.48)
## Good and bad numbers: a heal, a gain; damage, a loss.
const GOOD_COLOR := Color("5ad07a")
const BAD_COLOR := Color("e2504a")
## The rim of a cell by the item in it: a fragment, a legendary, boots, a potion.
const RIM_FRAGMENT := Color("8ea2b8")
const RIM_LEGENDARY := Color("e0b04c")
const RIM_BOOTS := Color("5fc7a8")
const RIM_POTION := Color("c9706a")
## A styled button's soft click, quiet under the game's sounds.
const CLICK_DB := -10.0
## Set on a button once its click is connected, so a restyle adds no second.
const CLICK_META := &"click_sound"

## theme(): a slider's dark track (its height is twice the margin).
const TRACK_COLOR := Color(0.025, 0.03, 0.045)
const TRACK_MARGIN := 5.0
## A dropdown and its pop-up list.
const FIELD_FONT := 17
const LIST_COLOR := Color(0.07, 0.085, 0.115)
const LIST_ROW_GAP := 10
## A scroll bar's width is twice the margin.
const SCROLL_MARGIN := 4.0
const SLIDER_GRABBER := preload("res://assets/art/ui/slider_grabber.svg")
const SLIDER_GRABBER_HL := preload("res://assets/art/ui/slider_grabber_hl.svg")
const OPTION_ARROW := preload("res://assets/art/ui/option_arrow.svg")
const OPTION_CHECK := preload("res://assets/art/ui/option_check.svg")
const TOGGLE_ON := preload("res://assets/art/ui/toggle_on.svg")
const TOGGLE_OFF := preload("res://assets/art/ui/toggle_off.svg")
const TOGGLE_ON_DISABLED := preload("res://assets/art/ui/toggle_on_disabled.svg")
const TOGGLE_OFF_DISABLED := preload("res://assets/art/ui/toggle_off_disabled.svg")

static var _theme: Theme


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


## Connects a button's soft click, once (CLICK_META marks it).
static func add_click(button: BaseButton) -> void:
	if button.has_meta(CLICK_META):
		return
	button.set_meta(CLICK_META, true)
	button.pressed.connect(func() -> void: Sfx.play(&"click", CLICK_DB))


## Applies the button look and its click. `selected` keeps it lit, e.g. the
## open tab.
static func style_button(button: Button, font_size := 22, selected := false) -> void:
	add_click(button)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override(&"font_size", font_size)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, button_style(state, selected))
	button.add_theme_color_override(&"font_color", TITLE_COLOR if selected else TEXT_COLOR)
	button.add_theme_color_override(&"font_hover_color", TITLE_COLOR)
	button.add_theme_color_override(&"font_disabled_color", DISABLED_FONT)


## A cell's box: a dark well with a thin rim (gold when `lit`).
static func cell_style(rim := CELL_BORDER, lit := false, radius := 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CELL_COLOR
	style.border_color = GOLD_COLOR if lit else rim
	style.set_border_width_all(2 if lit else 1)
	style.set_corner_radius_all(radius)
	return style


## The rim colour for the item in a cell (CELL_BORDER for an empty one).
static func item_rim(item: ItemData) -> Color:
	if item == null:
		return CELL_BORDER
	if item.is_potion():
		return RIM_POTION
	if item.is_boots():
		return RIM_BOOTS
	if item.is_fragment():
		return RIM_FRAGMENT
	return RIM_LEGENDARY


static func label(text: String, font_size := 18, color := TEXT_COLOR) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override(&"font_size", font_size)
	result.add_theme_color_override(&"font_color", color)
	return result


## Gold and navy for Godot's own widgets: sliders, dropdowns and their pop-up
## lists, on/off switches, scroll bars and separators. Set it on a screen's
## root control (the settings panel); a dropdown's list, a window of its own,
## inherits it from the dropdown. Built once and shared.
static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_slider_theme()
	_option_theme()
	_list_theme()
	_theme.set_icon(&"checked", &"CheckButton", TOGGLE_ON)
	_theme.set_icon(&"unchecked", &"CheckButton", TOGGLE_OFF)
	_theme.set_icon(&"checked_disabled", &"CheckButton", TOGGLE_ON_DISABLED)
	_theme.set_icon(&"unchecked_disabled", &"CheckButton", TOGGLE_OFF_DISABLED)
	_theme.set_stylebox(&"focus", &"CheckButton", StyleBoxEmpty.new())
	for type: StringName in [&"VScrollBar", &"HScrollBar"]:
		_theme.set_stylebox(&"scroll", type, panel(Color(1, 1, 1, 0.04), BORDER_COLOR, 0, SCROLL_MARGIN, 4))
		_theme.set_stylebox(&"scroll_focus", type, _theme.get_stylebox(&"scroll", type))
		_theme.set_stylebox(&"grabber", type, panel(Color(BORDER_COLOR, 0.6), BORDER_COLOR, 0, SCROLL_MARGIN, 4))
		_theme.set_stylebox(&"grabber_highlight", type, panel(GOLD_COLOR, GOLD_COLOR, 0, SCROLL_MARGIN, 4))
		_theme.set_stylebox(&"grabber_pressed", type, _theme.get_stylebox(&"grabber_highlight", type))
	var line := StyleBoxLine.new()
	line.color = Color(BORDER_COLOR, 0.3)
	line.thickness = 1
	_theme.set_stylebox(&"separator", &"HSeparator", line)
	_theme.set_constant(&"separation", &"HSeparator", 12)
	return _theme


## A dark rounded track, filled gold up to a gold diamond.
static func _slider_theme() -> void:
	_theme.set_stylebox(&"slider", &"HSlider", panel(TRACK_COLOR, Color(BORDER_COLOR, 0.35), 1, TRACK_MARGIN, 5))
	_theme.set_stylebox(&"grabber_area", &"HSlider", panel(BORDER_COLOR, BORDER_COLOR, 0, TRACK_MARGIN, 5))
	_theme.set_stylebox(&"grabber_area_highlight", &"HSlider", panel(GOLD_COLOR, GOLD_COLOR, 0, TRACK_MARGIN, 5))
	_theme.set_icon(&"grabber", &"HSlider", SLIDER_GRABBER)
	_theme.set_icon(&"grabber_highlight", &"HSlider", SLIDER_GRABBER_HL)
	_theme.set_icon(&"grabber_disabled", &"HSlider", SLIDER_GRABBER)


## Navy with a gold border and a gold arrow (tinted like the text, so it
## greys out with a disabled dropdown).
static func _option_theme() -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var style := button_style(state)
		style.set_border_width_all(1)
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		if state == &"normal":
			style.border_color = Color(BORDER_COLOR, 0.6)
		_theme.set_stylebox(state, &"OptionButton", style)
		_theme.set_stylebox(String(state) + "_mirrored", &"OptionButton", style)
	_theme.set_stylebox(&"focus", &"OptionButton", StyleBoxEmpty.new())
	_theme.set_icon(&"arrow", &"OptionButton", OPTION_ARROW)
	_theme.set_constant(&"arrow_margin", &"OptionButton", 14)
	_theme.set_constant(&"modulate_arrow", &"OptionButton", 1)
	_theme.set_font_size(&"font_size", &"OptionButton", FIELD_FONT)
	_field_colors(&"OptionButton")
	_theme.set_color(&"font_focus_color", &"OptionButton", TEXT_COLOR)
	_theme.set_color(&"font_pressed_color", &"OptionButton", TITLE_COLOR)
	_theme.set_color(&"font_hover_pressed_color", &"OptionButton", TITLE_COLOR)


## A dropdown's pop-up list: a navy panel, a gold-tinted hover and a gold
## diamond beside the chosen entry.
static func _list_theme() -> void:
	var list := panel(LIST_COLOR, BORDER_COLOR, 1, 6.0, 6)
	list.shadow_color = Color(0, 0, 0, 0.5)
	list.shadow_size = 10
	_theme.set_stylebox(&"panel", &"PopupMenu", list)
	var hover := panel(Color(GOLD_COLOR, 0.16), Color(GOLD_COLOR, 0.45), 1, 0.0, 4)
	_theme.set_stylebox(&"hover", &"PopupMenu", hover)
	# The other entries keep the diamond's room blank, so the names line up.
	var blank := ImageTexture.create_from_image(Image.create_empty(OPTION_CHECK.get_width(), OPTION_CHECK.get_height(), false, Image.FORMAT_RGBA8))
	for suffix: String in ["", "_disabled"]:
		_theme.set_icon("radio_checked" + suffix, &"PopupMenu", OPTION_CHECK)
		_theme.set_icon("radio_unchecked" + suffix, &"PopupMenu", blank)
	_theme.set_constant(&"v_separation", &"PopupMenu", LIST_ROW_GAP)
	_theme.set_constant(&"h_separation", &"PopupMenu", 10)
	_theme.set_constant(&"item_start_padding", &"PopupMenu", 10)
	_theme.set_constant(&"item_end_padding", &"PopupMenu", 16)
	_theme.set_font_size(&"font_size", &"PopupMenu", FIELD_FONT)
	_field_colors(&"PopupMenu")


## The text colours a dropdown and its list share: light, gold-white when
## hovered, grey when disabled.
static func _field_colors(type: StringName) -> void:
	_theme.set_color(&"font_color", type, TEXT_COLOR)
	_theme.set_color(&"font_hover_color", type, TITLE_COLOR)
	_theme.set_color(&"font_disabled_color", type, DISABLED_FONT)

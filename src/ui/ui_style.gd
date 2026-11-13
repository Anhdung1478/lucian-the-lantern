class_name UiStyle
extends RefCounted
## Shared look of the menu-style screens: dark navy panels with a gold border
## and buttons that light up gold on hover. theme() gives the same look to
## Godot's own widgets (sliders, dropdowns, switches, scroll bars). The type
## and space tokens below are the only sizes to use; the motion kit's manual
## is at the top of ui_motion.gd.

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
## A lighter navy for a hovered or chosen surface: depth by surface, not glow.
const SURFACE_RAISED := Color(0.10, 0.125, 0.17)

## Type sizes, in code units (screen px at 1600x900 in brackets). FONT_TAG
## (11.7 px) only for key tabs and stack counts inside cells; FONT_NOTE (12.5
## px) is the smallest note anywhere; FONT_BODY (14 px) the smallest body
## text; FONT_ROW (16.7 px) a row's name; FONT_LEAD (20 px) a panel's lead.
const FONT_TAG := 14
const FONT_NOTE := 15
const FONT_BODY := 17
const FONT_ROW := 20
const FONT_LEAD := 24
## A note's line spacing: the font's own height plus this gives a line height
## of 1.6 at FONT_NOTE (the floor is 1.3). It is Godot's default; never less.
const NOTE_LINE_SPACING := 3
## Space, in code units: GAP_S (5 px) inside a group, GAP (8 px) between
## neighbours, GAP_L (12 px) between groups, INSET (12 px) the least distance
## from words to the edge of their box, STACK (8 px) between stacked plates.
const GAP_S := 6
const GAP := 10
const GAP_L := 14
const INSET := 14
const STACK := 10
## price_row(): text to amount, amount to icon, and the icon's size.
const PRICE_GAP := 10
const PRICE_ICON_GAP := 7
const PRICE_ICON := 24.0

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
## open tab. The hover look eases in and out over UiMotion.FAST (ButtonLook);
## pressed stays immediate. Restyling (calling it again) is fine; to move the
## selection with an eased look use set_selected().
static func style_button(button: Button, font_size := 22, selected := false) -> void:
	add_click(button)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override(&"font_size", font_size)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, button_style(state, selected))
	button.add_theme_color_override(&"font_color", TITLE_COLOR if selected else TEXT_COLOR)
	button.add_theme_color_override(&"font_hover_color", TITLE_COLOR)
	button.add_theme_color_override(&"font_disabled_color", DISABLED_FONT)
	ButtonLook.of(button).adopt()


## Moves a styled button in or out of the selected look, easing its fill and
## font colour over UiMotion.FAST instead of restyling it (at once while
## UiMotion.off()). `fill` false: the rest fill turns clear and only the font
## eases (a tab under a SlideHighlight). A button never styled is styled.
static func set_selected(button: Button, on: bool, fill := true) -> void:
	if not button.has_meta(ButtonLook.META):
		style_button(button, button.get_theme_font_size(&"font_size"), on)
		if not fill:
			ButtonLook.of(button).select(on, false)
		return
	ButtonLook.of(button).select(on, fill)


## A cell's box: a dark well with a thin rim (gold when `lit`).
static func cell_style(rim := CELL_BORDER, lit := false, radius := 4) -> StyleBoxFlat:
	return cell_style_t(rim, 1.0 if lit else 0.0, radius)


## A cell's box part way to lit (UiMotion.lit's `lit_t`, 0 to 1): the rim
## goes from `rim` to gold and from 1 to 2 wide (2 from halfway).
static func cell_style_t(rim := CELL_BORDER, lit_t := 0.0, radius := 4) -> StyleBoxFlat:
	var t := clampf(lit_t, 0.0, 1.0)
	var style := StyleBoxFlat.new()
	style.bg_color = CELL_COLOR
	style.border_color = rim.lerp(GOLD_COLOR, t)
	style.set_border_width_all(2 if t >= 0.5 else 1)
	style.set_corner_radius_all(radius)
	return style


## A price inside a button, as one centred group: `text`, GAP, `amount`, a
## small gap, `icon` (PRICE_ICON high): "Purchase 25 [essence]". Add it as the
## button's child and leave button.text empty; it fills the button and
## centres itself, its labels take the button's font colour as it changes
## (hover, pressed, disabled) and its icon dims with a disabled button. Give
## the button a custom_minimum_size at least the row's. The amount is a
## CountLabel (price_amount()); `text` may be "" for an amount alone.
static func price_row(text: String, amount: Variant, icon: Texture2D, font_size := FONT_ROW) -> HBoxContainer:
	return PriceRow.new(text, amount, icon, font_size)


## A price_row's amount, to set_value() or read.
static func price_amount(row: Control) -> CountLabel:
	return row.get_node(^"Amount") as CountLabel


## A price_row's words.
static func price_text(row: Control) -> Label:
	return row.get_node(^"Text") as Label


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


## A small note: FONT_NOTE in `color`, wrapping at `width` when given.
static func note(text: String, color := DIM_COLOR, width := 0.0) -> Label:
	var result := label(text, FONT_NOTE, color)
	result.add_theme_constant_override(&"line_spacing", NOTE_LINE_SPACING)
	if width > 0.0:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.custom_minimum_size.x = width
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


## price_row(): text, amount and icon as one centred group filling its
## parent; inside a button it follows the button's state (the font colour for
## what the button draws now, a dimmed icon when disabled).
class PriceRow extends HBoxContainer:
	var _button: Button
	var _pending := false

	func _init(text: String, amount: Variant, icon: Texture2D, font_size: int) -> void:
		name = &"PriceRow"
		set_anchors_preset(Control.PRESET_FULL_RECT)
		alignment = BoxContainer.ALIGNMENT_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override(&"separation", 0)
		var words := UiStyle.label(text, font_size)
		words.name = &"Text"
		words.visible = text != ""
		add_child(words)
		_gap(UiStyle.PRICE_GAP, words.visible)
		var number := CountLabel.new()
		number.name = &"Amount"
		number.add_theme_font_size_override(&"font_size", font_size)
		number.add_theme_color_override(&"font_color", UiStyle.TEXT_COLOR)
		if amount is int:
			number.set_value(amount, true)
		else:
			number.formatter = func(_v: int) -> String: return str(amount)
		add_child(number)
		_gap(UiStyle.PRICE_ICON_GAP, icon != null)
		var picture := TextureRect.new()
		picture.name = &"Icon"
		picture.texture = icon
		picture.visible = icon != null
		picture.custom_minimum_size = Vector2(UiStyle.PRICE_ICON, UiStyle.PRICE_ICON)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(picture)
		for part: Control in get_children():
			part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for part: Label in [words, number]:
			part.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	func _gap(width: float, shown: bool) -> void:
		var gap := Control.new()
		gap.custom_minimum_size.x = width
		gap.visible = shown
		add_child(gap)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PARENTED:
			_button = get_parent() as Button
			if _button:
				_button.draw.connect(_queue_sync)
				_sync()
		elif what == NOTIFICATION_UNPARENTED:
			if _button and is_instance_valid(_button) and _button.draw.is_connected(_queue_sync):
				_button.draw.disconnect(_queue_sync)
			_button = null

	## The button redraws on every change of state; the colours follow.
	func _queue_sync() -> void:
		if not _pending:
			_pending = true
			_sync.call_deferred()

	func _sync() -> void:
		_pending = false
		if _button == null or not is_instance_valid(_button):
			return
		var color: Color
		match _button.get_draw_mode():
			BaseButton.DRAW_DISABLED:
				color = _button.get_theme_color(&"font_disabled_color")
			BaseButton.DRAW_HOVER:
				color = _button.get_theme_color(&"font_hover_color")
			BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED:
				color = _button.get_theme_color(&"font_pressed_color")
			_:
				color = _button.get_theme_color(&"font_color")
		for part: Label in [get_node(^"Text"), get_node(^"Amount")]:
			if part.get_theme_color(&"font_color") != color:
				part.add_theme_color_override(&"font_color", color)
		(get_node(^"Icon") as CanvasItem).modulate = Color(1, 1, 1, 0.45) if _button.disabled else Color.WHITE


## A styled button's eased looks (style_button, set_selected). Its rest and
## hover boxes stay two StyleBoxFlats with their usual colours whenever no
## ease runs; while one runs both carry the in-between colours, so the look
## moves smoothly whichever box the button draws. Pressed stays immediate. A
## box restyled in place (shape, margins, colours) is read again at the start
## of each ease. A button lit by MenuKeys (its rest box set to its hover box)
## is left to MenuKeys.
class ButtonLook extends RefCounted:
	const META := &"ui_button_look"

	var button: Button
	## The boxes style_button gave it, which the eases drive.
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	## 0 at rest, 1 hovered.
	var hover_t := 0.0
	var rest_bg := Color()
	var rest_border := Color()
	var peak_bg := Color()
	var peak_border := Color()
	var _hover_tween: Tween
	var _select_tween: Tween

	static func of(target: Button) -> ButtonLook:
		if target.has_meta(META):
			return target.get_meta(META)
		var look := ButtonLook.new()
		look.button = target
		target.set_meta(META, look)
		target.mouse_entered.connect(look._on_hover.bind(true))
		target.mouse_exited.connect(look._on_hover.bind(false))
		return look

	## style_button gave the button new boxes: drive those from now on.
	func adopt() -> void:
		_kill(_select_tween)
		_select_tween = null
		_kill(_hover_tween)
		_hover_tween = null
		normal = _box(&"normal")
		hover = _box(&"hover")
		hover_t = 1.0 if button.is_inside_tree() and button.is_hovered() else 0.0

	## True while the hover or selected look is easing.
	func is_easing() -> bool:
		return _running(_hover_tween) or _running(_select_tween)

	func select(on: bool, fill: bool) -> void:
		_kill(_select_tween)
		_select_tween = null
		if not _boxes_ok():
			return
		var goal := UiStyle.button_style(&"normal", on)
		var goal_bg := goal.bg_color if fill else Color(goal.bg_color, 0.0)
		var goal_border := goal.border_color if fill else Color(goal.border_color, 0.0)
		var goal_font := UiStyle.TITLE_COLOR if on else UiStyle.TEXT_COLOR
		if not _running(_hover_tween):
			_snapshot()
		var step := _apply_select.bind(rest_bg, rest_border, button.get_theme_color(&"font_color"), goal_bg, goal_border,
			goal_font)
		if UiMotion.off() or not button.is_inside_tree():
			step.call(1.0)
			return
		_select_tween = UiMotion.tween(button)
		_select_tween.tween_method(step, 0.0, 1.0, UiMotion.FAST)

	func _on_hover(inside: bool) -> void:
		var target := 1.0 if inside else 0.0
		var keys_lit := hover != null and _box(&"normal") == hover
		if not _boxes_ok() or keys_lit or button.disabled or not button.is_inside_tree() or UiMotion.off():
			_settle_hover()
			hover_t = target
			return
		if not _running(_hover_tween):
			_snapshot()
		_kill(_hover_tween)
		# Both boxes take the look on show now, so the box the button switches
		# to this frame starts from it (no one-frame flash).
		_apply_hover(hover_t)
		_hover_tween = UiMotion.tween(button)
		_hover_tween.tween_method(_apply_hover, hover_t, target, UiMotion.FAST)
		_hover_tween.tween_callback(_settle_hover)

	func _apply_hover(t: float) -> void:
		hover_t = t
		var bg := rest_bg.lerp(peak_bg, t)
		var border := rest_border.lerp(peak_border, t)
		for box: StyleBoxFlat in [normal, hover]:
			box.bg_color = bg
			box.border_color = border

	## Ends a hover ease: the rest box back to its rest colours, the hover box
	## to its hover ones.
	func _settle_hover() -> void:
		if _hover_tween == null:
			return
		_kill(_hover_tween)
		_hover_tween = null
		if _boxes_ok():
			normal.bg_color = rest_bg
			normal.border_color = rest_border
			hover.bg_color = peak_bg
			hover.border_color = peak_border

	func _apply_select(u: float, from_bg: Color, from_border: Color, from_font: Color, to_bg: Color, to_border: Color,
			to_font: Color) -> void:
		rest_bg = from_bg.lerp(to_bg, u)
		rest_border = from_border.lerp(to_border, u)
		button.add_theme_color_override(&"font_color", from_font.lerp(to_font, u))
		if _running(_hover_tween):
			_apply_hover(hover_t)
		else:
			normal.bg_color = rest_bg
			normal.border_color = rest_border

	func _snapshot() -> void:
		rest_bg = normal.bg_color
		rest_border = normal.border_color
		peak_bg = hover.bg_color
		peak_border = hover.border_color

	## The boxes are still the ones style_button gave (or MenuKeys lit it).
	func _boxes_ok() -> bool:
		if normal == null or hover == null or _box(&"hover") != hover:
			return false
		var shown := _box(&"normal")
		return shown == normal or shown == hover

	func _box(state: StringName) -> StyleBoxFlat:
		if not button.has_theme_stylebox_override(state):
			return null
		return button.get_theme_stylebox(state) as StyleBoxFlat

	static func _running(tween: Tween) -> bool:
		return tween != null and tween.is_valid() and tween.is_running()

	static func _kill(tween: Tween) -> void:
		if tween != null and tween.is_valid():
			tween.kill()

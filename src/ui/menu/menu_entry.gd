class_name MenuEntry
extends Button
## One row of a menu card (MenuCard): a tinted icon, its label (`text`) and
## an optional dim hint at its right. PRIMARY is the gold main choice; NORMAL
## is navy and lights gold on hover, with a bar at its left; DANGER does the
## same in red (leaving, exiting). disable() greys it with a hover note.
## Hover (and the arrow keys' light, key_light) ease the fill, border and
## colours over UiMotion.FAST. The hint hides itself when it would sit closer
## than HINT_GAP to the label.

enum Kind { PRIMARY, NORMAL, DANGER }

const SIZE := Vector2(380, 58)
const FONT := 22
const HINT_FONT := 15
const ICON_SIZE := 26
## The least space between the label and its hint (16 px on screen).
const HINT_GAP := 19.0
## The bar at its left on hover and press.
const BAR_WIDTH := 4
## Content margins: left, right.
const MARGIN := Vector2(18, 16)
const PRIMARY_FILL := Color(0.3, 0.22, 0.08, 0.95)
const PRIMARY_HOVER := Color(0.4, 0.3, 0.1, 0.98)
const NORMAL_FILL := Color(0.06, 0.08, 0.12, 0.88)
const NORMAL_HOVER := Color(0.11, 0.13, 0.18, 0.95)
const DISABLED_FILL := Color(0.05, 0.06, 0.08, 0.8)
const DISABLED_BORDER := Color(0.2, 0.22, 0.26)
const ICON_GOLD := Color("c9a45c")
const DANGER_ICON := Color("d0786c")
const DANGER_TEXT := Color("ffd2cb")

var kind: Kind
## The dim note at the right ("Slot 1", "Title screen").
var hint_label := Label.new()

## The two boxes the hover ease drives, and the colours it runs between.
var _normal_box: StyleBoxFlat
var _hover_box: StyleBoxFlat
var _rest_bg := Color()
var _peak_bg := Color()
var _rest_border := Color()
var _peak_border := Color()
var _rest_font := Color()
var _peak_font := Color()
var _rest_icon := Color()
var _peak_icon := Color()
var _hovered := false
var _keyed := false


func _init(label := "", icon_texture: Texture2D = null, entry_kind: Kind = Kind.NORMAL, hint := "") -> void:
	text = label
	icon = icon_texture
	kind = entry_kind
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = true
	add_theme_constant_override(&"icon_max_width", ICON_SIZE)
	add_theme_constant_override(&"h_separation", 14)
	add_theme_font_size_override(&"font_size", FONT)
	UiStyle.add_click(self)
	_style()
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.offset_right = -MARGIN.y
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.add_theme_font_size_override(&"font_size", HINT_FONT)
	hint_label.add_theme_color_override(&"font_color", UiStyle.DIM_COLOR)
	add_child(hint_label)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	resized.connect(_fit_hint)
	set_hint(hint)


## The dim note at the right; hidden when "".
func set_hint(note: String) -> void:
	hint_label.text = note
	_fit_hint()


## Shows the hint unless it is empty or there is no room for it at HINT_GAP
## from the label.
func _fit_hint() -> void:
	if hint_label.text == "":
		hint_label.visible = false
		return
	var label_width := get_theme_font(&"font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT).x
	var hint_width := hint_label.get_theme_font(&"font").get_string_size(hint_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_FONT).x
	var icon_width := ICON_SIZE + 14.0 if icon != null else 0.0
	var room := maxf(size.x, custom_minimum_size.x) - MARGIN.x - icon_width - label_width - hint_width - MARGIN.y
	hint_label.visible = room >= HINT_GAP


## The arrow keys light this row (MenuKeys): it eases to its hover look as the
## mouse would.
func key_light(on: bool) -> void:
	_keyed = on
	_refresh_lit()


func _set_hovered(on: bool) -> void:
	_hovered = on
	_refresh_lit()


func _refresh_lit() -> void:
	UiMotion.lit(self, (_hovered or _keyed) and not disabled, _ease_look)


## The look `t` of the way from rest (0) to lit (1), in both boxes and the
## text and icon colours.
func _ease_look(t: float) -> void:
	for box: StyleBoxFlat in [_normal_box, _hover_box]:
		box.bg_color = _rest_bg.lerp(_peak_bg, t)
		box.border_color = _rest_border.lerp(_peak_border, t)
	var font := _rest_font.lerp(_peak_font, t)
	add_theme_color_override(&"font_color", font)
	add_theme_color_override(&"font_hover_color", font)
	var tint := _rest_icon.lerp(_peak_icon, t)
	add_theme_color_override(&"icon_normal_color", tint)
	add_theme_color_override(&"icon_hover_color", tint)


## Shows the icon in `color` in every state (an essence icon keeps its own
## colours with white); dimmer when disabled.
func set_icon_color(color: Color) -> void:
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color", &"icon_focus_color"]:
		add_theme_color_override(state, color)
	add_theme_color_override(&"icon_disabled_color", Color(color, 0.4))
	_rest_icon = color
	_peak_icon = color


## Greys the row and gives it a hover note.
func disable(note: String) -> void:
	disabled = true
	_refresh_lit()
	set_meta(&"hover_text", note)


func enable() -> void:
	disabled = false
	remove_meta(&"hover_text")


func _style() -> void:
	var primary := kind == Kind.PRIMARY
	var accent := UiStyle.ERROR_COLOR if kind == Kind.DANGER else UiStyle.GOLD_COLOR
	_normal_box = _box(PRIMARY_FILL if primary else NORMAL_FILL,
		UiStyle.GOLD_COLOR if primary else Color(UiStyle.BORDER_COLOR, 0.35), 2 if primary else 1, 0)
	_hover_box = _box(PRIMARY_HOVER if primary else NORMAL_HOVER, accent, 2, BAR_WIDTH)
	_rest_bg = _normal_box.bg_color
	_rest_border = _normal_box.border_color
	_peak_bg = _hover_box.bg_color
	_peak_border = _hover_box.border_color
	add_theme_stylebox_override(&"normal", _normal_box)
	add_theme_stylebox_override(&"hover", _hover_box)
	for state: StringName in [&"pressed", &"hover_pressed"]:
		add_theme_stylebox_override(state, _box(Color(accent.darkened(0.7), 0.95), accent, 2, BAR_WIDTH))
	add_theme_stylebox_override(&"disabled", _box(DISABLED_FILL, DISABLED_BORDER, 1, 0))
	add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	var lit_text := DANGER_TEXT if kind == Kind.DANGER else UiStyle.TITLE_COLOR
	_rest_font = UiStyle.TITLE_COLOR if primary else UiStyle.TEXT_COLOR
	_peak_font = lit_text
	add_theme_color_override(&"font_color", _rest_font)
	add_theme_color_override(&"font_hover_color", lit_text)
	for state: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		add_theme_color_override(state, lit_text)
	add_theme_color_override(&"font_disabled_color", UiStyle.DISABLED_FONT)
	_rest_icon = UiStyle.TITLE_COLOR if primary else (DANGER_ICON if kind == Kind.DANGER else ICON_GOLD)
	_peak_icon = UiStyle.TITLE_COLOR if primary else accent
	add_theme_color_override(&"icon_normal_color", _rest_icon)
	for state: StringName in [&"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color"]:
		add_theme_color_override(state, _peak_icon)
	add_theme_color_override(&"icon_disabled_color", Color(1, 1, 1, 0.25))


## A row's box: `fill`, a `width` border in `border`, `bar` px on the left.
static func _box(fill: Color, border: Color, width: int, bar: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.border_width_left = maxi(width, bar)
	style.set_corner_radius_all(6)
	style.content_margin_left = MARGIN.x
	style.content_margin_right = MARGIN.y
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

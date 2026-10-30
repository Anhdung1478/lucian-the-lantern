class_name FreeBadge
extends Label
## A small "FREE" pill with a green-gold fill and a slow pulse. It marks an
## Evolution Tree upgrade that costs nothing and is ready to take. It ignores
## the mouse and only runs its pulse while it shows.

const SIZE := Vector2(48, 20)
const FONT := 13
const FILL_COLOR := Color("5f8f2e")
const BORDER_COLOR := Color("ffe08a")
const TEXT_COLOR := Color("fff7d6")
## One full pulse, in seconds, and how far the pill dims at its low point.
const PULSE_TIME := 1.8
const PULSE_LOW := 0.72


func _init() -> void:
	text = "FREE"
	size = SIZE
	custom_minimum_size = SIZE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override(&"font_size", FONT)
	add_theme_color_override(&"font_color", TEXT_COLOR)
	add_theme_stylebox_override(&"normal", UiStyle.panel(FILL_COLOR, BORDER_COLOR, 1, 0.0, 10))
	visibility_changed.connect(_sync_pulse)
	_sync_pulse()


func _process(_delta: float) -> void:
	var wave := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * TAU / PULSE_TIME)
	modulate.a = lerpf(PULSE_LOW, 1.0, wave)


func _sync_pulse() -> void:
	set_process(is_visible_in_tree())
	if not is_visible_in_tree():
		modulate.a = 1.0

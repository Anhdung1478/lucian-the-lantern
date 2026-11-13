class_name CountLabel
extends Label
## A number that counts to its new value instead of jumping: gold, essences,
## costs, a result's stats. set_value(v) counts from the shown value to `v`
## over a time that grows with the change (COUNT_MIN to COUNT_MAX s, cubic
## ease-out), rounding each frame; a new value while counting carries on from
## the shown one. The first value, a value while the label is outside the
## tree, `instant` and any value while UiMotion.off() land at once. The text
## is `format % value` ("%d", "+%d blue essence"), or `formatter.call(value)`
## when one is set ("%d / %d"). reserve() keeps room for the widest text so
## neighbours stay still while it counts. With `flash`, a gain tints the text
## GOOD_COLOR and a loss BAD_COLOR, easing back to its own colour.

## The count's time: COUNT_BASE + COUNT_PER * |change| s, held to COUNT_MIN..COUNT_MAX.
const COUNT_BASE := 0.15
const COUNT_PER := 0.0015
const COUNT_MIN := 0.2
const COUNT_MAX := 0.6
## How long a flash takes to ease back to the label's own colour.
const FLASH_TIME := 0.4

## The value counted to (the last set_value()).
var value := 0
## The value on show now (it trails `value` while counting).
var shown := 0
## The text for a value: `format % value` unless `formatter` is set.
var format := "%d":
	set(text):
		format = text
		_show(shown)
## (int) -> String; when valid it makes the text instead of `format`.
var formatter := Callable():
	set(callable):
		formatter = callable
		_show(shown)
## Tint a gain GOOD_COLOR and a loss BAD_COLOR for a moment.
var flash := false

var _has_value := false
var _count: Tween
var _flash: Tween
## The label's own font colour, while a flash runs (null: none of its own).
var _own_color: Variant = null
var _flashing := false


func _init(start := 0, text_format := "%d") -> void:
	format = text_format
	set_value(start, true)
	_has_value = false


## Counts to `v` (or jumps there with `instant`).
func set_value(v: int, instant := false) -> void:
	var delta := v - value
	value = v
	if instant or not _has_value or not is_inside_tree() or UiMotion.off():
		_has_value = true
		_stop_count()
		_show(v)
		return
	if delta == 0 and (_count == null or not _count.is_running()):
		return
	if flash and delta != 0:
		_flash_to(UiStyle.GOOD_COLOR if delta > 0 else UiStyle.BAD_COLOR)
	_stop_count()
	var from := shown
	var time := clampf(COUNT_BASE + COUNT_PER * absf(v - from), COUNT_MIN, COUNT_MAX)
	_count = UiMotion.tween(self)
	_count.tween_method(func(f: float) -> void: _show(roundi(f)), float(from), float(v), time)


## The text the label ends on (what a test reads).
func final_text() -> String:
	return text_for(value)


## The text for `v`.
func text_for(v: int) -> String:
	if formatter.is_valid():
		return formatter.call(v)
	return format % v if format.contains("%") else format


## Keeps room for `sample` (the widest text it will show, e.g. "99999"), so
## the label never grows while it counts.
func reserve(sample: String) -> void:
	var font := get_theme_font(&"font")
	var width := font.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size(&"font_size")).x
	var box := get_theme_stylebox(&"normal")
	if box:
		width += box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT)
	custom_minimum_size.x = maxf(custom_minimum_size.x, ceilf(width))


## Ends a count at once, on `value`.
func finish() -> void:
	_stop_count()
	_show(value)


func is_counting() -> bool:
	return _count != null and _count.is_valid() and _count.is_running()


func _show(v: int) -> void:
	shown = v
	text = text_for(v)


func _stop_count() -> void:
	if _count and _count.is_valid():
		_count.kill()
	_count = null


func _flash_to(tint: Color) -> void:
	if not _flashing:
		_own_color = get_theme_color(&"font_color") if has_theme_color_override(&"font_color") else null
		_flashing = true
	var own: Color = _own_color if _own_color != null else get_theme_color(&"font_color")
	if _flash and _flash.is_valid():
		_flash.kill()
	add_theme_color_override(&"font_color", tint)
	_flash = UiMotion.tween(self)
	_flash.tween_method(func(c: Color) -> void: add_theme_color_override(&"font_color", c), tint, own, FLASH_TIME)
	_flash.tween_callback(_end_flash)


func _end_flash() -> void:
	_flashing = false
	if _own_color == null:
		remove_theme_color_override(&"font_color")
	else:
		add_theme_color_override(&"font_color", _own_color)
	_own_color = null

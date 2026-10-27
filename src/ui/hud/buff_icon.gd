class_name BuffIcon
extends Control
## One small buff icon above the HUD panel, like LoL: the icon, a sweep for
## the time that has run out, a number (stacks, charge, shield) and a gold
## pulsing frame when the buff is ready (e.g. the next attack is Energized).
## Hovering shows what it does.

const SIZE := 36.0
const FRAME := Color(0.36, 0.4, 0.48)
const READY := Color("ffcf5a")
const SWEEP := Color(0, 0, 0, 0.55)

## {id, name, icon, text, count, left, duration, ready}; see Lucian.buffs().
var buff := {}:
	set(value):
		buff = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = MOUSE_FILTER_PASS


func tooltip_content() -> Control:
	return TooltipCard.buff(buff) if not buff.is_empty() else null


func tooltip_place() -> HoverTip.Place:
	return HoverTip.Place.ABOVE


func _process(_delta: float) -> void:
	if buff.get("ready", false):
		queue_redraw()


func _draw() -> void:
	if buff.is_empty():
		return
	var rect := Rect2(Vector2.ZERO, Vector2(SIZE, SIZE))
	draw_rect(rect, Color(0.05, 0.06, 0.08))
	if buff.icon:
		draw_texture_rect(buff.icon, rect.grow(-2.0), false)
	var duration: float = buff.duration
	if duration > 0.0:
		var spent := 1.0 - clampf(buff.left / duration, 0.0, 1.0)
		if spent > 0.005:
			draw_colored_polygon(SkillSlot.sweep_polygon(spent, SIZE), SWEEP)
	if buff.ready:
		var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
		draw_rect(rect.grow(-1.0), Color(READY, pulse), false, 3.0)
	else:
		draw_rect(rect, FRAME, false, 1.5)
	var count: String = buff.count
	if count != "":
		var font := ThemeDB.fallback_font
		var at := Vector2(0, SIZE - 2.0)
		draw_string_outline(font, at, count, HORIZONTAL_ALIGNMENT_RIGHT, SIZE - 2.0, 13, 4, Color.BLACK)
		draw_string(font, at, count, HORIZONTAL_ALIGNMENT_RIGHT, SIZE - 2.0, 13, Color.WHITE)

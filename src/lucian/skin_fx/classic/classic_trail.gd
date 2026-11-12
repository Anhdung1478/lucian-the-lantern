class_name ClassicTrail
extends FxTrail
## Classic's E: a streak of light along the dash with three fading echoes
## of Lucian's shape, and a small ring where he lands.

const STREAK := Color(1.0, 0.95, 0.75, 0.8)
const BAND := Color(UiStyle.LANTERN_COLOR, 0.14)
const EDGE := Color(UiStyle.LANTERN_COLOR, 0.6)
const ECHO := Color(1.0, 0.92, 0.6)
## Where the echoes stand, as shares of the trail, oldest first.
const ECHOES := [0.3, 0.55, 0.8]
const RING_RADIUS := 24.0


func _draw() -> void:
	draw_rect(Rect2(0, -24, length, 48), BAND)
	for offset: float in STREAK_OFFSETS:
		draw_line(Vector2(0, offset), Vector2(length, offset), Color(STREAK, STREAK.a * (1.0 - absf(offset) / 24.0)), 3.0)
	draw_arc(Vector2(length, 0), RING_RADIUS, 0.0, TAU, 32, EDGE, 2.0)
	if body == null:
		return
	var half := body.get_size() * 0.5
	for i in ECHOES.size():
		draw_texture(body, Vector2(ECHOES[i] * length, 0) - half, Color(ECHO, 0.15 + 0.1 * i))

class_name ClassicTrail
extends FxTrail
## Classic's E: a smoothly tapered gold-and-teal Sentinel light wake along the
## dash, ghostly echoes of Lucian's shape, shimmering light motes, and a
## sanctum ring where he lands.

const STREAK := Color(1.0, 0.96, 0.78, 0.88)
const BAND_TAIL := Color(UiStyle.LANTERN_COLOR, 0.0)
const BAND_HEAD := Color(UiStyle.LANTERN_COLOR, 0.26)
const GOLD_HEAD := Color(UiStyle.GOLD_COLOR, 0.34)
const EDGE := Color(UiStyle.LANTERN_COLOR, 0.78)
const ECHO := Color(1.0, 0.93, 0.65)
const MOTE := Color(1.0, 0.96, 0.78, 0.85)
## Where the echoes stand, as shares of the trail, oldest first.
const ECHOES := [0.3, 0.55, 0.8]
const RING_RADIUS := 24.0
const MOTE_STEP := 34.0


func _grown(from_x: float, to_x: float) -> void:
	var x := ceilf(from_x / MOTE_STEP) * MOTE_STEP
	while x <= to_x:
		sparks.emit(Vector2(x, randf_range(-16.0, 16.0)), Vector2(randf_range(-25.0, 15.0), randf_range(-32.0, 32.0)),
			randf_range(0.22, 0.38), randf_range(1.6, 2.8), MOTE if randf() < 0.65 else EDGE)
		x += MOTE_STEP


func _draw() -> void:
	if length <= 1.0:
		return
	# Smoothly tapered gold-and-teal velocity wake (zero width/alpha at origin).
	DashTrail.draw_tapered_ribbon(self, length, 28.0, BAND_TAIL, BAND_HEAD, true)
	DashTrail.draw_tapered_ribbon(self, length, 14.0, Color(UiStyle.GOLD_COLOR, 0.0), GOLD_HEAD, true)
	for offset: float in STREAK_OFFSETS:
		var weight := 1.0 - absf(offset) / 24.0
		var col := STREAK if offset == 0.0 else EDGE
		DashTrail.draw_speed_needle(self, length * 0.05, length, offset * 0.2, offset, 2.8 * weight, Color(col, col.a * weight))
	# Crisp Sentinel landing ring & glow at Lucian's position.
	SoftShape.ellipse(self, Vector2(length, 0), Vector2.ONE * (RING_RADIUS * 1.15), Color(EDGE, 0.22), 0.25)
	draw_arc(Vector2(length, 0), RING_RADIUS, 0.0, TAU, 36, EDGE, 2.2, true)
	draw_arc(Vector2(length, 0), RING_RADIUS * 0.68, 0.0, TAU, 28, Color(STREAK, 0.55), 1.4, true)
	sparks.draw_on(self)
	if body == null:
		return
	var half := body.get_size() * 0.5
	for i in ECHOES.size():
		var at := Vector2(ECHOES[i] * length, 0) - half
		var a := 0.16 + 0.14 * i
		draw_texture(body, at + Vector2(-2.0, 0.0), Color(EDGE, a * 0.55))
		draw_texture(body, at, Color(ECHO, a))

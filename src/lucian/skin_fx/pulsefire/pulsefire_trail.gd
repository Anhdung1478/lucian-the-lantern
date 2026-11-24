class_name PulsefireTrail
extends FxTrail
## Pulsefire's E: a glowing sapphire chrono-warp wake tapering smoothly from
## origin to Lucian, a vanishing circular chrono portal-ring at departure, and
## crisp translucent chrono echoes along the dash.

const DEEP_HEAD := Color(0.24, 0.36, 1.0, 0.32)
const BAND_HEAD := Color(0.48, 0.86, 1.0, 0.38)
const RING := Color(0.55, 0.9, 1.0, 0.85)
const CORE := Color("f4f8ff")
const IMAGE := Color(0.52, 0.84, 1.0)
## Where the afterimages stand, as shares of the trail, oldest first.
const IMAGES := [0.22, 0.44, 0.66, 0.86]
const RING_RADIUS := 28.0
const SPARK_STEP := 38.0


func _grown(from_x: float, to_x: float) -> void:
	var x := ceilf(from_x / SPARK_STEP) * SPARK_STEP
	while x <= to_x:
		sparks.emit(Vector2(x, randf_range(-16.0, 16.0)), Vector2(randf_range(-30.0, 10.0), randf_range(-28.0, 28.0)),
			randf_range(0.22, 0.36), randf_range(1.6, 2.8), RING if randf() < 0.6 else CORE)
		x += SPARK_STEP


func _draw() -> void:
	if length <= 1.0:
		return
	# Glowing sapphire chrono-warp tapered wake (zero width/alpha at origin).
	DashTrail.draw_tapered_ribbon(self, length, 26.0, Color(DEEP_HEAD, 0.0), DEEP_HEAD, true)
	DashTrail.draw_tapered_ribbon(self, length, 14.0, Color(BAND_HEAD, 0.0), BAND_HEAD, true)
	DashTrail.draw_speed_needle(self, length * 0.06, length, 0.0, 0.0, 2.8, Color(CORE, 0.85))
	DashTrail.draw_speed_needle(self, length * 0.12, length * 0.96, -3.0, -13.0, 2.0, RING)
	DashTrail.draw_speed_needle(self, length * 0.12, length * 0.96, 3.0, 13.0, 2.0, RING)
	# Vanishing circular chrono portal-ring at departure (shrinks & fades gracefully).
	var portal_t := clampf(age / 0.32, 0.0, 1.0)
	var portal_a := 1.0 - portal_t
	if portal_a > 0.02:
		var pr := RING_RADIUS * (1.0 - 0.55 * portal_t)
		SoftShape.ellipse(self, Vector2.ZERO, Vector2(pr * 0.45, pr), Color(DEEP_HEAD, 0.45 * portal_a), 0.25)
		draw_polyline(PulsefireRing.ellipse(Vector2.ZERO, Vector2(pr * 0.42, pr), 0.0), Color(RING, 0.9 * portal_a), 2.6, true)
		draw_polyline(PulsefireRing.ellipse(Vector2.ZERO, Vector2(pr * 0.28, pr * 0.68), 0.0), Color(CORE, 0.72 * portal_a), 1.5, true)
	# Sleek arrival halo at Lucian's position.
	draw_arc(Vector2(length, 0), RING_RADIUS * 0.85, 0.0, TAU, 36, Color(RING, 0.65), 2.0, true)
	sparks.draw_on(self)
	if body == null:
		return
	var half := body.get_size() * 0.5
	for i in IMAGES.size():
		var a := 0.14 + 0.14 * i
		var at := Vector2(IMAGES[i] * length, 0) - half
		draw_texture(body, at, Color(IMAGE, a))
		# Subtle chrono halo rim behind each echo.
		draw_arc(Vector2(IMAGES[i] * length, 0), 16.0, 0.0, TAU, 20, Color(RING, a * 0.45), 1.4, true)

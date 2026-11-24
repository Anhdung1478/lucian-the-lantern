class_name BlinkSparks
extends Node2D
## Flash's mark: a golden implosion/warp flare where Lucian stood (local
## origin) and, when `arrival_offset` is set, a crisp golden starburst and
## arrival ripple at his landing spot.

const LIFETIME := 0.6
const COUNT := 16
const ARRIVAL_COUNT := 10
## The sparks start around Lucian's body and drift up to this much farther out.
const RADIUS := 32.0
const DRIFT := 28.0
## How far they float up over their life.
const RISE := 18.0
const COLOR := Color("ffd84a")
const WARM := Color("ffae2b")
const CORE_COLOR := Color("fffbe8")

## Offset from departure (`position`) to Lucian's landing position.
var arrival_offset := Vector2.ZERO

## One per departure spark: angle, distance factor and size.
var _sparks: Array[Vector3] = []
## One per arrival sparkle: angle, distance factor and size.
var _arrival_sparks: Array[Vector3] = []
var _age := 0.0


func _ready() -> void:
	for i in COUNT:
		_sparks.append(Vector3(TAU * (i + randf_range(-0.3, 0.3)) / COUNT, randf_range(0.75, 1.18), randf_range(2.2, 4.0)))
	for i in ARRIVAL_COUNT:
		_arrival_sparks.append(Vector3(TAU * (i + randf_range(-0.3, 0.3)) / ARRIVAL_COUNT, randf_range(0.55, 1.15), randf_range(2.0, 3.6)))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	var fade := 1.0 - t
	var out := 1.0 - pow(1.0 - t, 2.4)
	# --- Departure: golden implosion/warp flare at Vector2.ZERO ---
	if t < 0.45:
		var dt := 1.0 - t / 0.45
		# Imploding golden warp ring collapsing inward.
		var impl_r := lerpf(42.0, 6.0, 1.0 - dt * dt)
		draw_arc(Vector2.ZERO, impl_r, 0.0, TAU, 40, Color(COLOR, 0.78 * dt), lerpf(1.2, 3.8, dt), true)
		SoftShape.ellipse(self, Vector2.ZERO, Vector2.ONE * lerpf(36.0, 12.0, 1.0 - dt), Color(WARM, 0.42 * dt), 0.25)
		ClassicStar.draw(self, Vector2.ZERO, lerpf(32.0, 6.0, 1.0 - dt), PI * 0.25, Color(CORE_COLOR, 0.9 * dt), 0.18)
	# Subtle outward residual ring.
	draw_arc(Vector2.ZERO, RADIUS + DRIFT * out, 0.0, TAU, 48, Color(COLOR, 0.45 * fade * fade), lerpf(2.8, 0.8, t), true)
	for spark in _sparks:
		var point := Vector2.from_angle(spark.x) * (RADIUS * spark.y + DRIFT * out) + Vector2(0, -RISE * t)
		var size := spark.z * (0.35 + 0.65 * fade)
		_draw_diamond_spark(point, size, fade)

	# --- Arrival: crisp golden starburst & ripple at `arrival_offset` ---
	if arrival_offset.length_squared() <= 1.0:
		return
	var at := arrival_offset
	if t < 0.55:
		var at_fade := 1.0 - t / 0.55
		SoftShape.ellipse(self, at, Vector2.ONE * lerpf(22.0, 52.0, 1.0 - at_fade), Color(COLOR, 0.45 * at_fade), 0.25)
		ClassicStar.draw(self, at, lerpf(44.0, 18.0, 1.0 - at_fade), 0.0, Color(COLOR, 0.85 * at_fade), 0.17)
		ClassicStar.draw(self, at, lerpf(30.0, 10.0, 1.0 - at_fade), PI * 0.25, Color(CORE_COLOR, 0.95 * at_fade), 0.18)
	# Double expanding arrival ripple rings.
	draw_arc(at, lerpf(12.0, 64.0, out), 0.0, TAU, 48, Color(COLOR, 0.72 * fade * fade), lerpf(3.6, 0.9, t), true)
	draw_arc(at, lerpf(6.0, 44.0, sqrt(t)), 0.0, TAU, 40, Color(CORE_COLOR, 0.55 * fade * fade), lerpf(2.2, 0.7, t), true)
	for spark in _arrival_sparks:
		var point := at + Vector2.from_angle(spark.x) * (14.0 + 38.0 * spark.y * out) + Vector2(0, -RISE * 1.1 * t)
		var size := spark.z * (0.35 + 0.65 * fade)
		_draw_diamond_spark(point, size, fade)


func _draw_diamond_spark(at: Vector2, size: float, alpha: float) -> void:
	draw_circle(at, size + 2.4, Color(WARM, 0.32 * alpha))
	var pts := PackedVector2Array([
		at + Vector2(0.0, -size * 1.45),
		at + Vector2(size * 0.95, 0.0),
		at + Vector2(0.0, size * 1.45),
		at + Vector2(-size * 0.95, 0.0),
	])
	draw_colored_polygon(pts, Color(COLOR, 0.95 * alpha))
	draw_circle(at, size * 0.42, Color(CORE_COLOR, alpha))

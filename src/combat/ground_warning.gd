class_name GroundWarning
extends Node2D
## A red mark on the ground before an enemy attack lands: a circle, a line
## (from the origin along `direction`), a cone, a lock line that follows a
## node, or a ring (a band round a circle). Its fill grows over `warn_time`;
## then `fired` and it goes. With a strike set, Lucian takes the hit if he
## is inside when it fires.

signal fired

enum Shape { CIRCLE, LINE, CONE, LOCK, RING }

const EDGE := Color(1.0, 0.25, 0.2, 0.9)
const FILL := Color(1.0, 0.2, 0.15, 0.3)
## Points round a ring's arcs.
const RING_POINTS := 96

var shape := Shape.CIRCLE
## The circle's or ring's radius, or the line's or cone's length.
var reach := 100.0
## The line's width, or the ring's band (half inside its radius, half out).
var width := 60.0
## The cone's angle, in radians.
var spread := deg_to_rad(70.0)
var direction := Vector2.RIGHT
var warn_time := 1.0
## LOCK: the node the line points at.
var follow: Node2D
## Played when it fires (&"" for none).
var sound := &""

var _elapsed := 0.0
var _hit: DamageInfo
var _victim: Lucian


static func circle(at: Vector2, radius: float, seconds: float) -> GroundWarning:
	var warning := GroundWarning.new()
	warning.position = at
	warning.reach = radius
	warning.warn_time = seconds
	return warning


static func line(from: Vector2, toward: Vector2, length: float, line_width: float, seconds: float) -> GroundWarning:
	var warning := GroundWarning.new()
	warning.shape = Shape.LINE
	warning.position = from
	warning.direction = toward.normalized()
	warning.reach = length
	warning.width = line_width
	warning.warn_time = seconds
	return warning


static func cone(from: Vector2, toward: Vector2, length: float, angle: float, seconds: float) -> GroundWarning:
	var warning := GroundWarning.new()
	warning.shape = Shape.CONE
	warning.position = from
	warning.direction = toward.normalized()
	warning.reach = length
	warning.spread = angle
	warning.warn_time = seconds
	return warning


## A thin line from `from` that keeps pointing at `onto` (Comeuppance).
static func lock(from: Vector2, onto: Node2D, seconds: float) -> GroundWarning:
	var warning := GroundWarning.new()
	warning.shape = Shape.LOCK
	warning.position = from
	warning.follow = onto
	warning.width = 8.0
	warning.warn_time = seconds
	return warning


## A band `band_width` wide round the circle of `radius` (The Box's walls
## rise on it): half of it inside the circle, half outside.
static func ring(at: Vector2, radius: float, band_width: float, seconds: float) -> GroundWarning:
	var warning := GroundWarning.new()
	warning.shape = Shape.RING
	warning.position = at
	warning.reach = radius
	warning.width = band_width
	warning.warn_time = seconds
	return warning


## Lucian takes `hit` if he is inside when the warning fires.
func strike(hit: DamageInfo, victim: Lucian) -> void:
	_hit = hit
	_victim = victim


## How far the warning has filled, 0 to 1.
func progress() -> float:
	return clampf(_elapsed / warn_time, 0.0, 1.0) if warn_time > 0.0 else 1.0


## A body of `radius` at `point` is inside.
func covers(point: Vector2, radius := 0.0) -> bool:
	match shape:
		Shape.CIRCLE:
			return in_circle(global_position, reach, point, radius)
		Shape.LINE:
			return in_line(global_position, direction, reach, width, point, radius)
		Shape.CONE:
			return in_cone(global_position, direction, reach, spread, point, radius)
		Shape.RING:
			return in_ring(global_position, reach, width, point, radius)
	return false


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if shape == Shape.LOCK and is_instance_valid(follow):
		direction = global_position.direction_to(follow.global_position)
		reach = global_position.distance_to(follow.global_position)
	queue_redraw()
	if _elapsed < warn_time:
		return
	if _hit and is_instance_valid(_victim) and covers(_victim.global_position, Lucian.HIT_RADIUS):
		_victim.take_damage(_hit)
	if sound != &"":
		Sfx.play(sound)
	fired.emit()
	queue_free()


static func in_circle(center: Vector2, radius: float, point: Vector2, point_radius := 0.0) -> bool:
	return center.distance_to(point) <= radius + point_radius


static func in_line(from: Vector2, toward: Vector2, length: float, line_width: float, point: Vector2, point_radius := 0.0) -> bool:
	var local := (point - from).rotated(-toward.angle())
	return local.x >= -point_radius and local.x <= length + point_radius and absf(local.y) <= line_width * 0.5 + point_radius


## On the band `band_width` wide centered on the circle of `radius`.
static func in_ring(center: Vector2, radius: float, band_width: float, point: Vector2, point_radius := 0.0) -> bool:
	return absf(center.distance_to(point) - radius) <= band_width * 0.5 + point_radius


static func in_cone(from: Vector2, toward: Vector2, length: float, angle: float, point: Vector2, point_radius := 0.0) -> bool:
	var offset := point - from
	if offset.length() > length + point_radius:
		return false
	return offset.length() <= point_radius or absf(toward.angle_to(offset)) <= angle * 0.5


func _draw() -> void:
	var fill := Color(FILL, FILL.a * (0.4 + 0.6 * progress()))
	match shape:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, reach * progress(), fill)
			draw_arc(Vector2.ZERO, reach, 0.0, TAU, 64, EDGE, 3.0, true)
		Shape.LINE, Shape.LOCK:
			draw_set_transform(Vector2.ZERO, direction.angle())
			draw_rect(Rect2(0.0, -width * 0.5, reach * progress(), width), fill)
			draw_rect(Rect2(0.0, -width * 0.5, reach, width), EDGE, false, 3.0 if shape == Shape.LINE else 2.0)
			draw_set_transform(Vector2.ZERO, 0.0)
		Shape.CONE:
			var points := PackedVector2Array([Vector2.ZERO])
			for i in 17:
				points.append(Vector2.from_angle(direction.angle() - spread * 0.5 + spread * i / 16.0) * reach)
			draw_colored_polygon(points, fill)
			points.append(Vector2.ZERO)
			draw_polyline(points, EDGE, 3.0, true)
		Shape.RING:
			# The band fills out from its middle line, between its two edges.
			if progress() > 0.0:
				draw_arc(Vector2.ZERO, reach, 0.0, TAU, RING_POINTS, fill, width * progress())
			for edge: float in [reach - width * 0.5, reach + width * 0.5]:
				draw_arc(Vector2.ZERO, maxf(edge, 0.0), 0.0, TAU, RING_POINTS, EDGE, 3.0, true)

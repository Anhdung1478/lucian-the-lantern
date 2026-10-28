class_name HomingMissile
extends Node2D
## Galeforce's missile: leaves slowly in its own direction, then curves onto
## its target, faster and tighter the longer it flies, leaving a trail. Hits
## unless the target disappears first.

const START_SPEED := 500.0
const MAX_SPEED := 2200.0
## Speed gained per second.
const ACCELERATION := 3500.0
## Turning speed (radians per second) at launch, and gained per second.
const START_TURN := 3.0
const TURN_GROWTH := 18.0
## Close enough to the target's center to count as a hit.
const HIT_DISTANCE := 20.0
const TRAIL_POINTS := 12

var color := Color("dff4ff")
var glow_color := Color(0.45, 0.75, 1.0, 0.55)

var _target: Enemy
var _info: DamageInfo
var _direction := Vector2.RIGHT
var _speed := START_SPEED
var _turn := START_TURN
## Recent global positions, oldest first.
var _trail := PackedVector2Array()


func launch(from: Vector2, direction: Vector2, target: Enemy, info: DamageInfo) -> void:
	position = from
	_direction = direction.normalized()
	rotation = _direction.angle()
	_target = target
	_info = info


func _physics_process(delta: float) -> void:
	if not Lucian.is_target(_target):
		queue_free()
		return
	var offset := _target.global_position - global_position
	var step := _speed * delta
	if offset.length() <= maxf(step, HIT_DISTANCE):
		_target.take_damage(_info)
		queue_free()
		return
	var turn := _turn * delta
	_direction = _direction.rotated(clampf(_direction.angle_to(offset), -turn, turn))
	_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
	_turn += TURN_GROWTH * delta
	_trail.append(global_position)
	if _trail.size() > TRAIL_POINTS:
		_trail.remove_at(0)
	global_position += _direction * step
	rotation = _direction.angle()
	queue_redraw()


func _draw() -> void:
	if _trail.size() >= 2:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for i in _trail.size():
			points.append(to_local(_trail[i]))
			colors.append(Color(glow_color, glow_color.a * float(i + 1) / _trail.size()))
		points.append(Vector2.ZERO)
		colors.append(glow_color)
		draw_polyline_colors(points, colors, 5.0, true)
	draw_line(Vector2(-14, 0), Vector2(4, 0), glow_color, 8.0)
	draw_line(Vector2(-10, 0), Vector2(4, 0), color, 3.0)

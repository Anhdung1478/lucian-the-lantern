class_name AttackProjectile
extends Node2D
## Homing basic-attack shot (also Runaan's bolts and Galeforce's missiles).
## Always hits unless the target disappears first.

const SPEED := 2800.0

var speed := SPEED
var color := Color("fffbe8")
var glow_color := Color(1.0, 0.85, 0.45, 0.5)

var _target: Enemy
var _info: DamageInfo


func launch(from: Vector2, target: Enemy, info: DamageInfo) -> void:
	position = from
	rotation = (target.global_position - from).angle()
	_target = target
	_info = info


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return
	var offset := _target.global_position - global_position
	var step := speed * delta
	if offset.length() <= step:
		_target.take_damage(_info)
		queue_free()
		return
	rotation = offset.angle()
	global_position += offset.normalized() * step


func _draw() -> void:
	draw_line(Vector2(-30, 0), Vector2.ZERO, glow_color, 8.0)
	draw_line(Vector2(-20, 0), Vector2(2, 0), color, 3.0)

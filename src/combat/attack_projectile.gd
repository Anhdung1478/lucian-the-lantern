class_name AttackProjectile
extends Node2D
## Homing basic-attack shot (also Runaan's bolts and Galeforce's missiles).
## Always hits unless the target disappears first.

const SPEED := 2800.0
const GLOW_RADIUS := 16.0

var speed := SPEED
var color := Color("fffbe8")
var glow_color := Color(1.0, 0.85, 0.45, 0.5)
## Drawn instead of the plain bolt when set (see set_look).
var look: ShotLook

var _target: Enemy
var _info: DamageInfo


func _ready() -> void:
	if look == null:
		ShotGlow.attach(self, GLOW_RADIUS)


func launch(from: Vector2, target: Enemy, info: DamageInfo) -> void:
	position = from
	rotation = (target.global_position - from).angle()
	_target = target
	_info = info


## Shows `new_look` instead of the plain bolt; null keeps what it has.
func set_look(new_look: ShotLook) -> void:
	if new_look == null:
		return
	look = new_look
	add_child(new_look)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not Lucian.is_target(_target):
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
	if look:
		return
	ShotLook.draw_bolt(self, color, glow_color)

class_name EnemyProjectile
extends Area2D
## An enemy's shot: flies straight, hits Lucian once (by distance) and stops
## on a wall or pillar. A boomerang flies `max_range` out, then back to its
## thrower, and may hit once each way.

## The shot hit Lucian and he took it (not blocked).
signal hit_lucian

var info: DamageInfo
var target: Lucian
var direction := Vector2.RIGHT
var speed := 450.0
var max_range := 600.0
var hit_radius := 12.0
var color := Color("c47cff")
## Boomerang: flies back to this node after max_range.
var return_to: Node2D
## Draws a chain back to this node (Thresh's hook).
var tether: Node2D

var _travelled := 0.0
var _returning := false
var _hit_this_pass := false


func launch(from: Vector2, toward: Vector2, hit: DamageInfo, foe: Lucian) -> void:
	position = from
	direction = toward.normalized()
	rotation = direction.angle()
	info = hit
	target = foe


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(func(_body: Node2D) -> void: queue_free())


func _physics_process(delta: float) -> void:
	var step := speed * delta
	if _returning:
		if not is_instance_valid(return_to):
			queue_free()
			return
		var offset := return_to.global_position - global_position
		if offset.length() <= step:
			queue_free()
			return
		direction = offset.normalized()
	global_position += direction * step
	rotation = direction.angle()
	_travelled += step
	if tether:
		queue_redraw()
	if not _hit_this_pass and is_instance_valid(target) and global_position.distance_to(target.global_position) <= hit_radius + Lucian.HIT_RADIUS:
		_hit_this_pass = true
		if target.take_damage(info):
			hit_lucian.emit()
	if not _returning and _travelled >= max_range:
		if return_to:
			_returning = true
			_hit_this_pass = false
		else:
			queue_free()


func _draw() -> void:
	if is_instance_valid(tether):
		draw_line(Vector2.ZERO, to_local(tether.global_position), color, 4.0)
	draw_circle(Vector2.ZERO, hit_radius, Color(color, 0.35))
	draw_circle(Vector2.ZERO, hit_radius * 0.55, color)

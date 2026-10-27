class_name LinearProjectile
extends Area2D
## A straight-flying shot (W missile, R bullets). Reports every enemy it
## touches; stops at the first one unless it pierces, or at max range.

signal hit_enemy(enemy: Enemy, prior_hits: int)
## Emitted once, where the shot ended. Connect deferred to run physics queries.
signal finished(at: Vector2)

var color := Color("fffbe8")
var glow_color := Color(1.0, 0.85, 0.45, 0.5)
var streak_length := 26.0
var streak_width := 4.0
## Above 0, a round glowing head is drawn (the W fireball).
var head_radius := 0.0

var _velocity := Vector2.ZERO
var _range_left := 0.0
var _pierce := false
var _hit: Array[Enemy] = []
var _stopped := false


func launch(from: Vector2, direction: Vector2, speed: float, max_range: float, radius: float, pierce := false) -> void:
	position = from
	rotation = direction.angle()
	_velocity = direction * speed
	_range_left = max_range
	_pierce = pierce
	collision_layer = 0
	collision_mask = Layers.ENEMY_HURTBOX
	monitorable = false
	var circle := CircleShape2D.new()
	circle.radius = radius
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _stopped:
		return
	var step := _velocity * delta
	position += step
	_range_left -= step.length()
	if _range_left <= 0.0:
		_stop()


func _draw() -> void:
	draw_line(Vector2(-streak_length * 1.4, 0), Vector2.ZERO, glow_color, streak_width * 2.6)
	draw_line(Vector2(-streak_length, 0), Vector2(streak_width * 0.5, 0), color, streak_width)
	if head_radius > 0.0:
		draw_circle(Vector2.ZERO, head_radius * 1.6, glow_color)
		draw_circle(Vector2.ZERO, head_radius, color)
		draw_circle(Vector2.ZERO, head_radius * 0.5, Color.WHITE)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if _stopped or hurtbox == null or not hurtbox.unit is Enemy or _hit.has(hurtbox.unit):
		return
	var enemy: Enemy = hurtbox.unit
	hit_enemy.emit(enemy, _hit.size())
	_hit.append(enemy)
	if not _pierce:
		_stop(enemy.global_position)


## A shot stopped by an enemy ends on that enemy, not at its edge.
func _stop(at := global_position) -> void:
	if _stopped:
		return
	_stopped = true
	finished.emit(at)
	queue_free()

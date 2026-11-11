class_name LinearProjectile
extends Area2D
## A straight-flying shot (W missile, R bullets). Reports every enemy it
## touches; stops at the first one unless it pierces, or at max range.
## Lucian's shots show their skin's ShotLook.

signal hit_enemy(enemy: Enemy, prior_hits: int)
## Emitted once, where the shot ended. Connect deferred to run physics queries.
signal finished(at: Vector2)

const GLOW_RADIUS := 18.0

var color := Color("fffbe8")
var glow_color := Color(1.0, 0.85, 0.45, 0.5)
var streak_length := 26.0
var streak_width := 4.0
## Above 0, a round glowing head is drawn (the W fireball).
var head_radius := 0.0
## Drawn instead of the plain streak when set (see set_look).
var look: ShotLook

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


func _ready() -> void:
	if look == null:
		ShotGlow.attach(self, maxf(head_radius * 2.0, GLOW_RADIUS))


## Shows `new_look` instead of the plain streak; null keeps what it has.
func set_look(new_look: ShotLook) -> void:
	if new_look == null:
		return
	look = new_look
	add_child(new_look)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _stopped:
		return
	var step := _velocity * delta
	position += step
	_range_left -= step.length()
	if _range_left <= 0.0:
		_stop()


func _draw() -> void:
	if look:
		return
	ShotLook.draw_streak(self, color, glow_color, streak_length, streak_width, head_radius)


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

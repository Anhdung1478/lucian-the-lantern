class_name HatefogZone
extends Node2D
## Malignance's Hatefog: scorched ground under an enemy hit by R. For
## DURATION seconds it deals magic damage every second to enemies inside and
## lowers their magic resist while they stand in it.

const DURATION := 3.0
const RADIUS := 150.0
const TICK := 1.0
const BASE_DAMAGE := 60.0
const AP_RATIO := 0.05
const FILL := Color(0.55, 0.1, 0.45, 0.28)
const EDGE := Color(0.9, 0.3, 0.8, 0.7)

var lucian: Lucian
var icon: Texture2D

var _left := DURATION
var _next_tick := 0.0


func setup(owner_lucian: Lucian, at: Vector2, status_icon: Texture2D) -> void:
	lucian = owner_lucian
	position = at
	icon = status_icon
	z_index = -1


func _physics_process(delta: float) -> void:
	_left -= delta
	_next_tick -= delta
	if _next_tick <= 0.0 and is_instance_valid(lucian):
		_next_tick += TICK
		for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
			if enemy.global_position.distance_to(global_position) <= RADIUS + enemy.radius:
				enemy.add_status(Enemy.HATEFOG, TICK + 0.1, 1, icon)
				enemy.take_damage(lucian.make_damage(BASE_DAMAGE + AP_RATIO * lucian.stats.ap, DamageInfo.Type.MAGIC, &"malignance"))
	if _left <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf(_left / 0.4, 0.0, 1.0)
	draw_circle(Vector2.ZERO, RADIUS, Color(FILL, FILL.a * fade))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 64, Color(EDGE, EDGE.a * fade), 3.0, true)
	var pulse := 0.5 + 0.5 * sin(_left * 9.0)
	draw_arc(Vector2.ZERO, RADIUS * (0.55 + 0.1 * pulse), 0.0, TAU, 48, Color(EDGE, 0.35 * fade), 2.0, true)

class_name Radar
extends Control
## Bottom right: the map as a dark panel with dots, no terrain. Lucian is a
## blue dot, an enemy red (an elite bigger), a boss a red skull (a mini boss
## a smaller one); Senna a small pale-blue dot and the merchant gold. Never
## takes clicks, so right-clicks under it still move Lucian.

const WIDTH := 260.0
const SKULL := preload("res://assets/art/ui/skull.svg")
const DOT := 4.0
const ELITE_DOT := 7.0
const SKULL_SIZE := 16.0
const MINI_BOSS_SKULL_SIZE := 12.0
const LUCIAN_DOT := 6.0
const LUCIAN_COLOR := Color("4fa8ff")
const ENEMY_COLOR := Color("e0475a")
const ALLY_COLOR := Color("a8d8ff")
const MERCHANT_COLOR := Color("ffcf5a")

var bounds := Rect2(0, 0, 4800, 2700)
var lucian: Lucian


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(map_bounds: Rect2, target: Lucian) -> void:
	bounds = map_bounds
	lucian = target
	custom_minimum_size = Vector2(WIDTH, roundf(WIDTH * bounds.size.y / bounds.size.x))
	size = custom_minimum_size


## Where a world point sits on the radar.
func to_radar(point: Vector2) -> Vector2:
	return (point - bounds.position) / bounds.size * size


static func dot_size(kind: StringName) -> float:
	match kind:
		&"boss":
			return SKULL_SIZE
		&"mini_boss":
			return MINI_BOSS_SKULL_SIZE
		&"elite":
			return ELITE_DOT
	return DOT


## An enemy gets a dot unless the Black Mist veils it.
static func shows(enemy: Enemy) -> bool:
	return not (enemy is EnemyUnit and (enemy as EnemyUnit).veiled)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_style_box(UiStyle.panel(Color(0.04, 0.05, 0.07, 0.88), Color(0.36, 0.4, 0.48), 2, 0.0, 6), Rect2(Vector2.ZERO, size))
	for merchant: Node2D in get_tree().get_nodes_in_group(&"merchants"):
		draw_circle(to_radar(merchant.global_position), DOT, MERCHANT_COLOR)
	for ally: Node2D in get_tree().get_nodes_in_group(&"allies"):
		draw_circle(to_radar(ally.global_position), DOT, ALLY_COLOR)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not shows(enemy):
			continue
		var kind := (enemy as EnemyUnit).data.kind if enemy is EnemyUnit else &"normal"
		var at := to_radar(enemy.global_position)
		if kind in EnemyData.BOSS_KINDS:
			var skull := dot_size(kind)
			draw_texture_rect(SKULL, Rect2(at - Vector2.ONE * skull * 0.5, Vector2.ONE * skull), false, ENEMY_COLOR)
		else:
			draw_circle(at, dot_size(kind), ENEMY_COLOR)
	if is_instance_valid(lucian):
		var at := to_radar(lucian.global_position)
		draw_circle(at, LUCIAN_DOT + 1.5, Color.WHITE)
		draw_circle(at, LUCIAN_DOT, LUCIAN_COLOR)

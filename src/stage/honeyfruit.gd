class_name Honeyfruit
extends Node2D
## A Honeyfruit plant on the jungle floor (3-4). Lucian walking over it
## (within PICKUP_RANGE of his body's edge) eats it: it heals HEAL plus
## HEAL_SHARE of his max HP, through Lucian.heal. Then it is an empty stalk
## for REGROW_TIME and grows back. Set `lucian` before adding it.

const ART := preload("res://assets/art/stage/honeyfruit.svg")
const PICKUP_RANGE := 50.0
const HEAL := 100.0
const HEAL_SHARE := 0.06
const REGROW_TIME := 30.0
## Drawn flat on the ground, under the units.
const Z := -1
const STALK := Color("5a3b1e")
const LEAF := Color("4f8a2e")
const OUTLINE := Color("1a1d24")

var lucian: Lucian

## Seconds until it is back; 0 while ripe.
var _regrow_left := 0.0


func _init() -> void:
	z_index = Z


## Ready to be eaten, not regrowing.
func is_ripe() -> bool:
	return _regrow_left <= 0.0


func _physics_process(delta: float) -> void:
	if not is_ripe():
		_regrow_left = maxf(_regrow_left - delta, 0.0)
		if is_ripe():
			queue_redraw()
		return
	if not is_instance_valid(lucian) or not lucian.can_act():
		return
	if global_position.distance_to(lucian.global_position) <= PICKUP_RANGE + Lucian.HIT_RADIUS:
		_eat()


func _eat() -> void:
	lucian.heal(HEAL + HEAL_SHARE * lucian.stats.max_hp)
	Sfx.play(&"potion")
	if not GameSettings.instance().low_effects():
		# Heal's green ring and crosses, over his art.
		var burst := HealBurst.new()
		lucian.add_child(burst)
		lucian.move_child(burst, lucian.visuals.get_index() + 1)
	_regrow_left = REGROW_TIME
	queue_redraw()


func _draw() -> void:
	if is_ripe():
		draw_texture(ART, -ART.get_size() * 0.5)
		return
	# The empty stalk: two leaves and a bare stem.
	for side in [-1.0, 1.0]:
		var leaf := PackedVector2Array([Vector2(0, 2), Vector2(14 * side, -6), Vector2(22 * side, 4), Vector2(10 * side, 8)])
		draw_colored_polygon(leaf, LEAF)
		leaf.append(leaf[0])
		draw_polyline(leaf, OUTLINE, 2.0, true)
	draw_line(Vector2(0, 4), Vector2(2, -10), STALK, 3.0, true)

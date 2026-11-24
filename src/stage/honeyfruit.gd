class_name Honeyfruit
extends Node2D
## A Honeyfruit plant on the jungle floor (3-4). Lucian walking over it
## (within PICKUP_RANGE of his body's edge) eats it: it heals HEAL plus
## HEAL_SHARE of his max HP, through Lucian.heal, and restores MANA plus
## MANA_SHARE of his max mana. It waits, ripe, while he is full on both. Then
## it is an empty stalk for REGROW_TIME and grows back. Set `lucian` before
## adding it.

const PICKUP_RANGE := 50.0
const HEAL := 100.0
const HEAL_SHARE := 0.06
const MANA := 60.0
const MANA_SHARE := 0.06
const REGROW_TIME := 30.0
## Drawn flat on the ground, under the units.
const Z := -1
const STALK := Color("5a3b1e")
const LEAF := Color("4f8a2e")
const OUTLINE := Color("1a1d24")
const LEAF_LIT := Color("7cc443")
const FRUIT := Color("f2b630")
const FRUIT_LIT := Color("ffe58a")
const FRUIT_SHADE := Color("c0781c")
const FRUIT_GLOW := Color("ffd36a")
## The fruit's size, the leaves' length, and its shadow's height.
const FRUIT_RADIUS := 13.0
const LEAF_LENGTH := 36.0
const SHADOW_HEIGHT := 9.0

var lucian: Lucian

## Seconds until it is back; 0 while ripe.
var _regrow_left := 0.0
var _ripe_time := 0.0
var _redraw_in := 0.0


func _init() -> void:
	z_index = Z


## Ready to be eaten, not regrowing.
func is_ripe() -> bool:
	return _regrow_left <= 0.0


func _process(delta: float) -> void:
	if not is_ripe() or not Juice.on():
		return
	_ripe_time += delta
	_redraw_in -= delta
	if _redraw_in <= 0.0:
		_redraw_in = 0.08
		queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_ripe():
		_regrow_left = maxf(_regrow_left - delta, 0.0)
		if is_ripe():
			queue_redraw()
		return
	if not is_instance_valid(lucian) or not lucian.can_act():
		return
	if lucian.hp >= lucian.stats.max_hp and lucian.mana >= lucian.stats.max_mana:
		return
	if global_position.distance_to(lucian.global_position) <= PICKUP_RANGE + Lucian.HIT_RADIUS:
		_eat()


func _eat() -> void:
	lucian.heal(HEAL + HEAL_SHARE * lucian.stats.max_hp)
	lucian.restore_mana(MANA + MANA_SHARE * lucian.stats.max_mana)
	Sfx.play(&"potion")
	if not GameSettings.instance().low_effects():
		# Heal's green ring and crosses, over his art.
		var burst := HealBurst.new()
		lucian.add_child(burst)
		lucian.move_child(burst, lucian.visuals.get_index() + 1)
	_regrow_left = REGROW_TIME
	queue_redraw()


func _draw() -> void:
	MapArt.round_shadow(self, Vector2.ZERO, FRUIT_RADIUS + 5.0, SHADOW_HEIGHT)
	if is_ripe():
		_draw_ripe()
		return
	# The empty stalk: two leaves and a bare stem.
	for side in [-1.0, 1.0]:
		var leaf := PackedVector2Array([Vector2(0, 2), Vector2(14 * side, -6), Vector2(22 * side, 4), Vector2(10 * side, 8)])
		draw_colored_polygon(leaf, LEAF)
		leaf.append(leaf[0])
		draw_polyline(leaf, OUTLINE, 2.0, true)
	draw_line(Vector2(0, 4), Vector2(2, -10), STALK, 3.0, true)


## Leaves round a warm gold fruit with a living shimmer/bob glow when ripe.
func _draw_ripe() -> void:
	var alive := Juice.on()
	var pulse := 0.5 + 0.5 * sin(_ripe_time * TAU * 0.48) if alive else 0.5
	var bob := Vector2(0.0, sin(_ripe_time * TAU * 0.62) * 2.2) if alive else Vector2.ZERO
	for angle in [0.5, 1.9, 3.3, 4.7]:
		MapArt.leaf(self, Vector2.ZERO, angle, LEAF_LENGTH, LEAF, LEAF_LIT)
	MapArt.glow(self, bob, FRUIT_RADIUS * (2.8 + 0.65 * pulse), Color(FRUIT_GLOW, 0.2 + 0.12 * pulse))
	MapArt.disc(self, bob, FRUIT_RADIUS + 2.0, OUTLINE)
	MapArt.disc(self, bob, FRUIT_RADIUS, FRUIT_SHADE)
	MapArt.disc(self, bob - MapArt.SHADOW_DIR * 1.5, FRUIT_RADIUS * 0.85, FRUIT)
	MapArt.disc(self, bob - MapArt.SHADOW_DIR * 5.0, FRUIT_RADIUS * 0.35, FRUIT_LIT)
	if alive:
		# Subtle living shimmer glint + tiny orbiting honey-gold pollen motes.
		var glint_a := 0.35 + 0.55 * pow(0.5 + 0.5 * sin(_ripe_time * TAU * 0.9), 2.0)
		var glint_at := bob - MapArt.SHADOW_DIR * 5.2
		draw_line(glint_at + Vector2(-4.0, 0), glint_at + Vector2(4.0, 0), Color(1.0, 0.98, 0.82, glint_a), 1.6, true)
		draw_line(glint_at + Vector2(0, -4.0), glint_at + Vector2(0, 4.0), Color(1.0, 0.98, 0.82, glint_a), 1.6, true)
		for i in 3:
			var ang := _ripe_time * 1.1 + TAU * i / 3.0
			var mote := bob + Vector2(cos(ang) * 20.0, sin(ang) * 14.0 - 4.0 * sin(_ripe_time * 2.0 + i))
			var ma := 0.4 + 0.4 * sin(_ripe_time * 3.0 + i * 2.1)
			draw_circle(mote, 2.0, Color(FRUIT_LIT, ma))

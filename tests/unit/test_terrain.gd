extends GutTest
## Act 3's terrain: lava and shallow water (HazardZone), Honeyfruit and Blast
## Cones.

const MAP_SIZE := Vector2(3000, 2000)
## A jungle clump 400 thick, from the top of the map to the bottom.
const CLUMP := [Vector2(1300, 0), Vector2(1700, 0), Vector2(1700, 2000), Vector2(1300, 2000)]
const PLANT_AT := Vector2(1000, 1000)

var lucian: Lucian
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	received.clear()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Shots and trails go here, so they are freed with the test.
	effects = Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.global_position = Vector2.ZERO
	lucian.damage_received.connect(func(info: DamageInfo, amount: float) -> void: received.append([info, amount]))


func _zone(zone: HazardZone) -> HazardZone:
	zone.lucian = lucian
	add_child_autofree(zone)
	return zone


func _buff_ids() -> Array:
	return lucian.buffs().map(func(buff: Dictionary) -> StringName: return buff.id)


## A map with CLUMP in it, `extra` walls too.
func _map(extra: Array[PackedVector2Array] = []) -> StageMap:
	var map := StageMap.new()
	map.size = MAP_SIZE
	map.wall_polygons.append(PackedVector2Array(CLUMP))
	map.wall_polygons.append_array(extra)
	add_child_autofree(map)
	return map


func _cone(map: StageMap, at := PLANT_AT) -> BlastCone:
	var cone := BlastCone.new()
	cone.lucian = lucian
	cone.arena = map
	cone.position = at
	add_child_autofree(cone)
	return cone


## A real shot on `target`: it deals its damage inside the physics callback
## (area_entered), where no body may be added and no query may run.
func _shoot(target: Enemy) -> void:
	var shot := LinearProjectile.new()
	shot.launch(target.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void:
		hit.take_damage(lucian.make_damage(10.0, DamageInfo.Type.PHYSICAL, &"q")))
	effects.add_child(shot)


func _hit() -> DamageInfo:
	return lucian.make_damage(10.0, DamageInfo.Type.PHYSICAL, &"basic")


# --- lava and water ---------------------------------------------------------


func test_lava_burns_lucian_while_inside_and_stops_half_a_second_after_he_leaves() -> void:
	_zone(HazardZone.burning(HazardZone.LAVA_DPS, DamageInfo.Type.MAGIC).set_circle(Vector2(60, 0), 160.0))
	await wait_seconds(1.1)
	assert_eq(received.size(), 2, "a tick every half second")
	var info: DamageInfo = received[0][0]
	assert_eq(info.type, DamageInfo.Type.MAGIC)
	assert_true(info.over_time)
	assert_almost_eq(info.amount, HazardZone.LAVA_DPS * DamageOverTime.TICK, 0.01)
	assert_true(_buff_ids().has(Lucian.BURNING), "shows in the buff row")
	lucian.global_position = Vector2(1000, 0)
	var on_leaving := received.size()
	await wait_seconds(0.7)
	assert_gt(received.size(), on_leaving, "it lingers")
	var lingered := received.size()
	await wait_seconds(0.6)
	assert_eq(received.size(), lingered, "then it stops")
	assert_false(_buff_ids().has(Lucian.BURNING))


func test_water_slows_lucian_by_a_quarter_while_inside() -> void:
	var speed := lucian.current_move_speed()
	var bank := PackedVector2Array([Vector2(-200, -100), Vector2(200, -100), Vector2(200, 100), Vector2(-200, 100)])
	_zone(HazardZone.slowing(HazardZone.WATER_SLOW).set_polygon(bank))
	await wait_physics_frames(2)
	assert_almost_eq(lucian.slow_amount(), 0.25, 0.001)
	assert_almost_eq(lucian.current_move_speed(), speed * 0.75, 0.01)
	await wait_seconds(0.4)
	assert_almost_eq(lucian.slow_amount(), 0.25, 0.001, "for as long as he stays")
	lucian.global_position = Vector2(0, 400)
	await wait_seconds(0.2)
	assert_eq(lucian.slow_amount(), 0.0, "it ends when he leaves")
	assert_almost_eq(lucian.current_move_speed(), speed, 0.01)


func test_a_zone_tells_inside_from_outside() -> void:
	var pool := HazardZone.burning(10.0, DamageInfo.Type.MAGIC).set_circle(Vector2(100, 100), 50.0)
	assert_true(pool.contains(Vector2(130, 100)))
	assert_false(pool.contains(Vector2(160, 100)))
	var bank := HazardZone.slowing(0.2).set_polygon(PackedVector2Array([Vector2(0, 0), Vector2(300, 0), Vector2(300, 50), Vector2(0, 50)]))
	assert_true(bank.contains(Vector2(250, 25)))
	assert_false(bank.contains(Vector2(250, 75)))
	assert_eq(bank.outline()[1], Vector2(300, 0), "the outline is where the zone is")
	pool.free()
	bank.free()


func test_a_zone_with_a_lifetime_goes_after_it() -> void:
	var zone := _zone(HazardZone.burning(30.0, DamageInfo.Type.MAGIC, 0.3).set_circle(Vector2(2000, 0), 100.0))
	await wait_seconds(0.2)
	assert_true(is_instance_valid(zone))
	await wait_seconds(0.3)
	assert_false(is_instance_valid(zone))


func test_a_thrown_lucian_flies_over_lava_unburned() -> void:
	_zone(HazardZone.burning(HazardZone.LAVA_DPS, DamageInfo.Type.MAGIC).set_circle(Vector2(300, 0), 100.0))
	lucian.launch(Vector2(600, 0), 0.3)
	await wait_seconds(0.5)
	assert_eq(received.size(), 0)
	assert_false(_buff_ids().has(Lucian.BURNING))


# --- Honeyfruit -------------------------------------------------------------


func test_honeyfruit_heals_once_then_regrows_at_30_s() -> void:
	lucian.hp = 100.0
	var fruit := Honeyfruit.new()
	fruit.lucian = lucian
	fruit.position = Vector2(1000, 0)
	add_child_autofree(fruit)
	await wait_physics_frames(2)
	assert_true(fruit.is_ripe(), "out of reach, it waits")
	lucian.global_position = fruit.position - Vector2(Honeyfruit.PICKUP_RANGE + Lucian.HIT_RADIUS - 5.0, 0)
	await wait_physics_frames(2)
	var healing := (Honeyfruit.HEAL + Honeyfruit.HEAL_SHARE * lucian.stats.max_hp) * (1.0 + lucian.stats.heal_shield_power)
	assert_almost_eq(lucian.hp, 100.0 + healing, 2.0)
	assert_false(fruit.is_ripe())
	var eaten := lucian.hp
	await wait_physics_frames(5)
	assert_almost_eq(lucian.hp, eaten, 1.0, "once")
	lucian.global_position = Vector2(3000, 0)
	fruit._physics_process(Honeyfruit.REGROW_TIME - 0.5)
	assert_false(fruit.is_ripe(), "still regrowing")
	fruit._physics_process(0.6)
	assert_true(fruit.is_ripe(), "back after 30 s")
	lucian.global_position = fruit.position
	await wait_physics_frames(2)
	assert_false(fruit.is_ripe(), "eaten again")


# --- Blast Cone -------------------------------------------------------------


func test_a_hit_throws_lucian_within_reach_over_the_wall_to_a_walkable_spot() -> void:
	var map := _map()
	lucian.global_position = PLANT_AT + Vector2(150, 0)
	var cone := _cone(map)
	await wait_physics_frames(1)
	_shoot(cone)
	await wait_physics_frames(3)
	assert_false(cone.is_alive(), "popped")
	assert_false(cone.is_in_group(&"plants"))
	assert_true(lucian.is_launched(), "thrown")
	await wait_seconds(BlastCone.THROW_TIME + 0.1)
	assert_false(lucian.is_launched())
	assert_almost_eq(lucian.global_position, PLANT_AT + Vector2(150 + BlastCone.THROW_DISTANCE, 0), Vector2(1, 1),
		"800 straight away from the plant, over the clump")
	assert_true(map.is_walkable(lucian.global_position, BlastCone.LANDING_MARGIN))
	assert_engine_error_count(0)


func test_the_landing_steps_back_to_the_farthest_walkable_spot() -> void:
	var map := _map([PackedVector2Array([Vector2(1900, 0), Vector2(2200, 0), Vector2(2200, 2000), Vector2(1900, 2000)])])
	var from := Vector2(1250, 1000)
	var to := BlastCone.landing_spot(Vector2(1100, 1000), from, map)
	assert_almost_eq(to, Vector2(1850, 1000), Vector2(0.01, 0.01), "back in 25 px steps to 40 px off the second wall")
	assert_true(map.is_walkable(to, BlastCone.LANDING_MARGIN))


func test_with_no_walkable_spot_far_enough_there_is_no_throw() -> void:
	var map := _map([PackedVector2Array([Vector2(1700, 0), Vector2(3000, 0), Vector2(3000, 2000), Vector2(1700, 2000)])])
	var from := PLANT_AT + Vector2(150, 0)
	assert_eq(BlastCone.landing_spot(PLANT_AT, from, map), from)
	lucian.global_position = from
	var cone := _cone(map)
	await wait_physics_frames(1)
	_shoot(cone)
	await wait_physics_frames(3)
	assert_false(cone.is_alive(), "popped all the same")
	assert_false(lucian.is_launched())
	assert_engine_error_count(0)


func test_it_does_not_throw_lucian_beyond_350() -> void:
	var map := _map()
	var away := PLANT_AT - Vector2(BlastCone.REACH + 30.0, 0)
	lucian.global_position = away
	var cone := _cone(map)
	await wait_physics_frames(1)
	_shoot(cone)
	await wait_physics_frames(3)
	assert_false(cone.is_alive(), "popped")
	assert_false(lucian.is_launched(), "too far to be thrown")
	await wait_seconds(0.3)
	assert_almost_eq(lucian.global_position, away, Vector2(1, 1))
	assert_engine_error_count(0)


func test_it_regrows_at_20_s() -> void:
	var cone := _cone(_map())
	lucian.global_position = Vector2(200, 1000)
	assert_eq(cone.take_damage(_hit()), 0.0)
	assert_false(cone.is_alive())
	assert_false(Lucian.is_target(cone))
	assert_null(lucian.enemy_at(cone.global_position), "nothing to click while it regrows")
	assert_eq(cone.take_damage(_hit()), 0.0)
	cone._physics_process(BlastCone.REGROW_TIME - 0.2)
	assert_false(cone.is_alive(), "still regrowing")
	cone._physics_process(0.3)
	assert_true(cone.is_alive(), "back after 20 s")
	assert_true(cone.is_in_group(&"plants"))
	assert_eq(lucian.enemy_at(cone.global_position), cone)
	await wait_physics_frames(2)
	assert_false(lucian.is_launched(), "the first pop was out of reach")


## Its art is 108 px wide: a click on a leaf tip, 46 from its middle, picks
## it; one just past the leaves doesn't.
func test_a_click_on_a_leaf_tip_picks_it() -> void:
	var cone := _cone(_map())
	assert_eq(BlastCone.ART.get_width(), 108)
	assert_eq(lucian.enemy_at(cone.global_position + Vector2(46, 0)), cone)
	assert_eq(lucian.enemy_at(cone.global_position + Vector2(0, -46)), cone)
	assert_null(lucian.enemy_at(cone.global_position + Vector2(60, 0)))


func test_a_burn_tick_does_not_pop_it() -> void:
	var cone := _cone(_map())
	var tick := _hit()
	tick.over_time = true
	cone.take_damage(tick)
	assert_true(cone.is_alive())


func test_it_is_never_in_enemies_but_a_left_click_gives_an_attack_order() -> void:
	var map := _map()
	lucian.global_position = PLANT_AT + Vector2(-250, 0)
	var cone := _cone(map)
	await wait_physics_frames(1)
	assert_false(cone.is_in_group(&"enemies"))
	assert_true(cone.is_in_group(&"plants"))
	assert_true(Lucian.is_target(cone))
	# A left-click: the controller asks enemy_at, then gives an attack order.
	assert_eq(lucian.enemy_at(cone.global_position), cone)
	# A + Left-click picks it under the cursor, but never as the weakest or nearest.
	assert_eq(lucian.attack_move_target(cone.global_position), cone)
	assert_null(lucian.attack_move_target(Vector2(200, 200)))
	watch_signals(cone)
	watch_signals(lucian)
	lucian.command_attack(lucian.enemy_at(cone.global_position))
	assert_eq(lucian._order, Lucian.Order.ATTACK)
	assert_eq(lucian._target, cone)
	var popped: bool = await wait_until(func() -> bool: return not cone.is_alive(), 3.0)
	assert_true(popped, "his shot pops it")
	assert_signal_not_emitted(cone, "died")
	assert_signal_not_emitted(lucian, "enemy_killed")
	await wait_physics_frames(2)
	assert_true(lucian.is_launched(), "and throws him")
	assert_engine_error_count(0)

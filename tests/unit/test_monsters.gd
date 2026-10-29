extends GutTest
## Act 3's jungle monsters (Monster): raptors swarm around Lucian, wolves
## come in from a side, Gromp spits poison from afar, Blue's slam slows,
## Red's hit burns, the Scuttler runs and escapes, a big Krug splits.

var lucian: Lucian
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	received.clear()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	# Bolts go here, so they are freed with the test.
	effects = Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	add_child_autofree(lucian)
	lucian.global_position = Vector2.ZERO
	lucian.damage_received.connect(func(info: DamageInfo, amount: float) -> void: received.append([info, amount]))


func _data(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


func _monster(id: String, at: Vector2) -> Monster:
	var monster := Monster.new()
	monster.setup(_data(id), 1, 1, lucian)
	monster.position = at
	monster.projectile_parent = effects
	add_child_autofree(monster)
	return monster


## The smallest angle between `a` and `b`, in degrees.
func _gap(a: float, b: float) -> float:
	return rad_to_deg(absf(angle_difference(a, b)))


func test_swarm_raptors_spread_around_lucian() -> void:
	var raptors: Array[Monster] = []
	for i in 5:
		raptors.append(_monster("raptor_big" if i == 0 else "raptor", Vector2(600, -80 + 40 * i)))
	await wait_seconds(3.0)
	var angles: Array[float] = []
	for raptor in raptors:
		assert_lte(raptor.distance_to_target(), raptor.attack_range + Lucian.HIT_RADIUS, "in range")
		angles.append((raptor.global_position - lucian.global_position).angle())
	for i in angles.size():
		for j in range(i + 1, angles.size()):
			assert_gt(_gap(angles[i], angles[j]), 25.0, "raptors %d and %d stand apart" % [i, j])
	var behind := raptors.filter(func(raptor: Monster) -> bool: return raptor.global_position.x < lucian.global_position.x)
	assert_gt(behind.size(), 0, "the pack wraps him: some go round to his far side")
	assert_gt(received.size(), 0, "and they bite")


func test_each_raptor_aims_at_its_own_angle() -> void:
	var first := _monster("raptor", Vector2(600, 0))
	var second := _monster("raptor", Vector2(600, 0))
	assert_gt(_gap(first.swarm_angle, second.swarm_angle), 25.0)


func test_wolves_come_in_from_a_side() -> void:
	var wolf := _monster("murkwolf", Vector2(900, 0))
	assert_true(wolf.flank_side == 1.0 or wolf.flank_side == -1.0, "left or right, set at spawn")
	var close: bool = await wait_until(func() -> bool: return wolf.distance_to_target() <= Monster.FLANK_CLOSE, 4.0)
	assert_true(close, "it got within %d" % Monster.FLANK_CLOSE)
	assert_gt(absf(wolf.global_position.y), 60.0, "it came round to his side, not straight in")
	# Heading -X, the line's orthogonal() is +Y.
	assert_eq(signf(wolf.global_position.y), wolf.flank_side, "the side it chose at spawn")
	var bitten: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.0)
	assert_true(bitten, "then it closes in and bites")


func test_gromp_keeps_its_distance_spits_and_poisons() -> void:
	var gromp := _monster("gromp", Vector2(200, 0))
	var poisoned: bool = await wait_until(func() -> bool: return lucian._burns.has(&"gromp"), 5.0)
	assert_true(poisoned, "its spit poisons")
	await wait_seconds(2.5)
	assert_between(gromp.distance_to_target(), 370.0, 490.0, "it keeps 380-480 away")
	var spits := received.filter(func(hit: Array) -> bool: return not hit[0].over_time)
	assert_gt(spits.size(), 0)
	assert_eq(spits[0][0].type, DamageInfo.Type.MAGIC, "a magic bolt")
	var ticks := received.filter(func(hit: Array) -> bool: return hit[0].over_time)
	assert_gt(ticks.size(), 0)
	assert_eq(ticks[0][0].type, DamageInfo.Type.MAGIC, "a magic poison")


func test_gromp_stands_still_when_it_spits() -> void:
	var gromp := _monster("gromp", Vector2(200, 0))
	await wait_physics_frames(1)
	gromp._attack_left = 0.0
	await wait_physics_frames(1)
	var at := gromp.global_position
	assert_eq(effects.get_children().filter(func(node: Node) -> bool: return node is EnemyProjectile).size(), 1, "it spat")
	# Physics frames, not real time: it stands SPIT_STAND of physics time.
	await wait_physics_frames(roundi((Monster.SPIT_STAND - 0.1) * Engine.physics_ticks_per_second))
	assert_almost_eq(gromp.global_position, at, Vector2(1, 1), "it stands while it spits, though he is too close")
	await wait_physics_frames(roundi(0.4 * Engine.physics_ticks_per_second))
	assert_gt(gromp.distance_to_target(), at.length() + 20.0, "then backs off")


func test_blues_slam_slows() -> void:
	var blue := _monster("blue_sentinel", Vector2(400, 0))
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.0)
	assert_true(hit)
	assert_almost_eq(lucian.slow_amount(), 0.3, 0.001)
	assert_almost_eq(lucian._slows[&"blue_sentinel"].left, 1.5, 0.05)
	assert_eq(received[0][0].type, DamageInfo.Type.PHYSICAL)
	assert_eq(blue.data.buff_on_kill, JungleBuffs.BLUE)


func test_reds_hit_burns() -> void:
	var red := _monster("red_brambleback", Vector2(400, 0))
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.0)
	assert_true(hit)
	assert_true(lucian._burns.has(&"red_brambleback"))
	assert_almost_eq(lucian._burns.time_left(&"red_brambleback"), 3.0, 0.05)
	assert_eq(received[0][0].type, DamageInfo.Type.PHYSICAL, "a physical hit")
	await wait_seconds(0.6)
	var ticks := received.filter(func(info: Array) -> bool: return info[0].over_time)
	assert_gt(ticks.size(), 0)
	assert_eq(ticks[0][0].type, DamageInfo.Type.MAGIC, "a magic burn")
	assert_eq(red.data.buff_on_kill, JungleBuffs.RED)


func test_the_burn_type_is_the_hits_unless_set() -> void:
	var data := EnemyData.new()
	data.damage_type = DamageInfo.Type.MAGIC
	assert_eq(data.burn_type(), DamageInfo.Type.MAGIC)
	data.hit_burn_type = DamageInfo.Type.TRUE
	assert_eq(data.burn_type(), DamageInfo.Type.TRUE)


func test_the_scuttler_runs_away_and_never_attacks() -> void:
	var scuttler := _monster("rift_scuttler", Vector2(150, 0))
	await wait_seconds(1.5)
	assert_gt(scuttler.distance_to_target(), 450.0, "it ran")
	assert_lt(absf(scuttler.global_position.y), 40.0, "straight away from him")
	assert_eq(received.size(), 0, "it deals no damage")


func test_the_scuttler_slides_along_a_wall_behind_it() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(40, 1600)
	shape.shape = box
	wall.position = Vector2(300, 0)
	wall.add_child(shape)
	add_child_autofree(wall)
	# Straight at the wall: dead on, it can only slide.
	var scuttler := _monster("rift_scuttler", Vector2(200, 0))
	await wait_seconds(2.5)
	assert_lt(scuttler.global_position.x, 280.0, "the wall held it")
	assert_gt(absf(scuttler.global_position.y), 150.0, "it slid along the wall")
	assert_gt(scuttler.distance_to_target(), 300.0, "away from him")


func test_the_scuttler_escapes_at_15_seconds() -> void:
	var scuttler := _monster("rift_scuttler", Vector2(150, 0))
	assert_eq(scuttler.data.escape_after, 15.0)
	await wait_physics_frames(1)
	scuttler._alive_time = 14.8
	await wait_physics_frames(1)
	assert_false(scuttler.has_escaped, "not before 15 s")
	await wait_seconds(0.3)
	assert_true(scuttler.has_escaped)
	assert_false(scuttler.is_in_group(&"enemies"))


func test_an_escaped_scuttler_never_comes_back_into_the_fight() -> void:
	var scuttler := _monster("rift_scuttler", Vector2(150, 0))
	scuttler.escape()
	scuttler.set_untargetable(true)
	scuttler.set_untargetable(false)
	assert_false(scuttler.is_in_group(&"enemies"))
	assert_eq(scuttler.collision_layer, 0)
	var dove := _monster("rift_scuttler", Vector2(-150, 0))
	dove.set_untargetable(true)
	dove.escape()
	dove.set_untargetable(false)
	assert_false(dove.is_in_group(&"enemies"), "untargetable when it escaped: still out")
	assert_eq(dove.collision_layer, 0)


func test_a_big_krug_splits_into_two_krugs() -> void:
	var data := _data("krug_big")
	assert_eq(data.split_into, &"krug")
	assert_eq(data.split_count, 2)
	assert_true(ResourceLoader.exists("res://data/enemies/%s.tres" % data.split_into))


func test_krugs_walk_in_and_hit() -> void:
	var krug := _monster("krug", Vector2(400, 0))
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 3.5)
	assert_true(hit)
	assert_lte(krug.distance_to_target(), krug.attack_range + Lucian.HIT_RADIUS + 5.0)

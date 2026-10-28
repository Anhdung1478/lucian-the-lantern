extends GutTest
## Skills cast by a real Lucian against a real training dummy.

const Slot := ChampionProgress.Slot
const DUMMY_ARMOR_MULTIPLIER := 100.0 / 130.0

var lucian: Lucian
var dummy: TrainingDummy
## [DamageInfo, final_amount] per hit.
var hits: Array[Array] = []


func before_each() -> void:
	hits.clear()
	dummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	dummy.position = Vector2(600, 0)
	add_child_autofree(dummy)
	dummy.damage_taken.connect(func(info: DamageInfo, final_amount: float) -> void: hits.append([info, final_amount]))
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)
	lucian.cheat_infinite_mana = true


func _rank(slot: ChampionProgress.Slot, times: int) -> void:
	for i in times:
		assert_true(lucian.try_rank_up(slot), "rank up %s" % slot)


func _sources() -> Array:
	return hits.map(func(hit: Array) -> StringName: return hit[0].source)


func test_q_fires_after_cast_time_and_hits_in_line() -> void:
	_rank(Slot.Q, 1)
	assert_true(lucian.try_cast(Slot.Q, dummy.position))
	await wait_physics_frames(3)
	assert_eq(hits.size(), 0, "no damage before the cast time ends")
	await wait_seconds(0.4)
	assert_eq(_sources(), [&"q"])
	assert_almost_eq(hits[0][1], (80.0 + 0.6 * 60.0) * DUMMY_ARMOR_MULTIPLIER, 0.01)


func test_q_misses_enemy_off_the_line() -> void:
	_rank(Slot.Q, 1)
	lucian.try_cast(Slot.Q, Vector2(0, 600))
	await wait_seconds(0.45)
	assert_eq(hits.size(), 0)


func test_q_max_rank_laser_is_wider() -> void:
	# 85 px off the line: outside half width 30 + hurtbox 44, inside 45 + 44.
	dummy.position = Vector2(600, 85)
	lucian.progress.set_level(9)
	_rank(Slot.Q, 4)
	lucian.try_cast(Slot.Q, Vector2(600, 0))
	await wait_seconds(0.45)
	assert_eq(hits.size(), 0, "rank 4 is too thin to reach")
	_rank(Slot.Q, 1)
	lucian.skills[Slot.Q].cooldown.clear()
	lucian.try_cast(Slot.Q, Vector2(600, 0))
	await wait_seconds(0.45)
	assert_eq(hits.size(), 1, "rank 5 is wide enough")


func test_q_max_rank_laser_is_longer() -> void:
	# Hurtbox edge at 870 - 44 = 826: past the 800 laser, inside the 900 one.
	dummy.position = Vector2(870, 0)
	lucian.progress.set_level(9)
	_rank(Slot.Q, 4)
	lucian.try_cast(Slot.Q, dummy.position)
	await wait_seconds(0.45)
	assert_eq(hits.size(), 0, "rank 4 is too short to reach")
	_rank(Slot.Q, 1)
	lucian.skills[Slot.Q].cooldown.clear()
	lucian.try_cast(Slot.Q, dummy.position)
	await wait_seconds(0.45)
	assert_eq(hits.size(), 1, "rank 5 is long enough")


func test_q_roots_lucian_during_cast() -> void:
	_rank(Slot.Q, 1)
	lucian.command_move(Vector2(-500, 0))
	lucian.try_cast(Slot.Q, dummy.position)
	await wait_seconds(0.2)
	assert_almost_eq(lucian.position.x, 0.0, 0.5)
	await wait_seconds(0.4)
	assert_lt(lucian.position.x, -10.0, "the move order resumes after the cast")


func test_attack_without_cast_fires_one_shot() -> void:
	lucian.command_attack(dummy)
	await wait_seconds(1.2)
	assert_eq(_sources(), [&"basic"])


func test_cast_charges_passive_for_a_double_shot() -> void:
	_rank(Slot.Q, 1)
	lucian.try_cast(Slot.Q, dummy.position)
	assert_true(lucian.passive.charged)
	lucian.command_attack(dummy)
	await wait_seconds(1.6)
	assert_eq(_sources(), [&"q", &"basic", &"lightslinger"])
	assert_false(lucian.passive.charged)
	var ad := lucian.stats.ad
	assert_almost_eq(hits[2][1], 0.6 * ad * DUMMY_ARMOR_MULTIPLIER, 0.01)


func test_shots_alternate_guns() -> void:
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	# Facing the dummy (right), the left gun is above his center (y < 0).
	var sides: Array[String] = []
	effects.child_entered_tree.connect(func(node: Node) -> void:
		if node is AttackProjectile:
			sides.append("L" if (node as Node2D).position.y < lucian.position.y else "R"))
	lucian.passive.fire_basic_attack(dummy)
	lucian.passive.fire_basic_attack(dummy)
	# Lightslinger's second shot comes from the other gun.
	lucian.passive.charge()
	lucian.passive.fire_basic_attack(dummy)
	await wait_seconds(0.25)
	lucian.passive.fire_basic_attack(dummy)
	assert_eq(sides, ["L", "R", "L", "R", "L"] as Array[String])


func test_failed_cast_does_not_charge_passive() -> void:
	lucian.try_cast(Slot.Q, dummy.position)
	assert_false(lucian.passive.charged)


func test_passive_hit_lowers_e_cooldown() -> void:
	var e_cooldown := lucian.skills[Slot.E].cooldown
	e_cooldown.start(10.0)
	lucian.on_damage_dealt(dummy, DamageInfo.create(10.0, DamageInfo.Type.PHYSICAL, &"lightslinger", lucian), 8.0)
	assert_almost_eq(e_cooldown.remaining, 9.0, 0.001)
	lucian.on_damage_dealt(dummy, DamageInfo.create(10.0, DamageInfo.Type.PHYSICAL, &"basic", lucian), 8.0)
	assert_almost_eq(e_cooldown.remaining, 9.0, 0.001)


func _add_wall(x: float) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 400)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector2(x, 0)
	add_child_autofree(wall)


func test_e_dashes_max_distance_through_enemies() -> void:
	dummy.position = Vector2(150, 0)
	_rank(Slot.E, 1)
	assert_true(lucian.try_cast(Slot.E, Vector2(2000, 0)))
	assert_true(lucian.is_dashing())
	await wait_seconds(0.5)
	assert_false(lucian.is_dashing())
	assert_almost_eq(lucian.position.x, 280.0, 2.0)
	assert_almost_eq(lucian.position.y, 0.0, 0.5)


func test_e_dashes_as_far_as_the_cursor_even_zero() -> void:
	dummy.position = Vector2(0, 600)
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	_rank(Slot.E, 1)
	lucian.try_cast(Slot.E, Vector2(50, 0))
	await wait_seconds(0.4)
	assert_almost_eq(lucian.position.x, 50.0, 2.0)
	lucian.skills[Slot.E].cooldown.clear()
	await wait_seconds(0.4)
	assert_true(lucian.try_cast(Slot.E, lucian.position), "aimed right on him")
	await wait_physics_frames(3)
	assert_almost_eq(lucian.position.x, 50.0, 0.5, "no move")
	assert_false(lucian.is_dashing())
	assert_eq(lucian.collision_mask, Layers.WORLD | Layers.ENEMY_BODY, "solid again")
	await wait_seconds(0.4)
	assert_eq(effects.get_child_count(), 0, "no trail left behind")


func test_e_stops_at_walls() -> void:
	dummy.position = Vector2(0, 600)
	_add_wall(300.0)
	await wait_physics_frames(2)
	_rank(Slot.E, 1)
	lucian.try_cast(Slot.E, Vector2(1000, 0))
	await wait_seconds(0.5)
	# Wall face at 290, Lucian's radius is 30.
	assert_almost_eq(lucian.position.x, 260.0, 2.0)
	assert_false(lucian.is_dashing())


func test_e_trail_grows_behind_lucian_then_fades() -> void:
	dummy.position = Vector2(0, 600)
	var effects := Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	_rank(Slot.E, 1)
	lucian.try_cast(Slot.E, Vector2(1000, 0))
	assert_eq(effects.get_child_count(), 1, "drawn from the start of the dash")
	var trail := effects.get_child(0) as DashTrail
	assert_not_null(trail)
	assert_eq(trail.color, DashTrail.LIGHT)
	assert_eq(trail.position, Vector2.ZERO, "from where the dash started")
	await wait_physics_frames(3)
	assert_almost_eq(trail.length, lucian.position.x, 0.5, "up to Lucian")
	assert_lt(trail.length, 280.0, "still growing")
	assert_eq(trail.modulate.a, 1.0, "no fading during the dash")
	# The dash takes 280 / 1350 = 0.21 s; the trail fades for 0.3 s after.
	await wait_seconds(0.25)
	assert_almost_eq(trail.length, 280.0, 2.0)
	assert_lt(trail.modulate.a, 1.0, "fading once it lands")


func test_no_other_casts_while_dashing() -> void:
	dummy.position = Vector2(0, 600)
	lucian.progress.set_level(3)
	_rank(Slot.E, 1)
	_rank(Slot.Q, 1)
	lucian.try_cast(Slot.E, Vector2(1000, 0))
	assert_false(lucian.try_cast(Slot.Q, Vector2(1000, 0)))


func test_e_keeps_the_attack_order() -> void:
	_rank(Slot.E, 1)
	lucian.command_attack(dummy)
	await wait_seconds(0.1)
	lucian.try_cast(Slot.E, Vector2(0, 400))
	await wait_seconds(1.5)
	assert_has(_sources(), &"basic")
	assert_has(_sources(), &"lightslinger", "E charged the passive")


const DUMMY_MR_MULTIPLIER := 100.0 / 130.0


func test_w_bursts_on_first_enemy_and_marks_it() -> void:
	_rank(Slot.W, 1)
	lucian.try_cast(Slot.W, dummy.position)
	await wait_seconds(0.8)
	assert_eq(_sources(), [&"w"])
	assert_eq(hits[0][0].type, DamageInfo.Type.MAGIC)
	assert_almost_eq(hits[0][1], 75.0 * DUMMY_MR_MULTIPLIER, 0.01)
	assert_true(dummy.has_mark(ArdentBlaze.MARK))


func test_w_bursts_at_max_range_and_cross_catches_enemies_beside_it() -> void:
	# The missile flies along y = 0 and misses; its cross ends 944 px out.
	dummy.position = Vector2(944, 150)
	_rank(Slot.W, 1)
	lucian.try_cast(Slot.W, Vector2(1000, 0))
	await wait_seconds(1.0)
	assert_eq(_sources(), [&"w"])


func test_w_max_rank_cross_is_bigger() -> void:
	# 250 px off the missile path: outside 200 + 44, inside 280 + 44.
	dummy.position = Vector2(944, 250)
	lucian.progress.set_level(9)
	_rank(Slot.W, 4)
	lucian.try_cast(Slot.W, Vector2(1000, 0))
	await wait_seconds(1.0)
	assert_eq(hits.size(), 0, "rank 4 cross is too small")
	_rank(Slot.W, 1)
	lucian.skills[Slot.W].cooldown.clear()
	lucian.try_cast(Slot.W, Vector2(1000, 0))
	await wait_seconds(1.0)
	assert_eq(hits.size(), 1, "rank 5 cross reaches")


func test_hitting_a_marked_enemy_gives_move_speed() -> void:
	_rank(Slot.W, 1)
	var base_speed := lucian.current_move_speed()
	dummy.add_mark(ArdentBlaze.MARK, 6.0)
	lucian.on_damage_dealt(dummy, DamageInfo.create(10.0, DamageInfo.Type.PHYSICAL, &"basic", lucian), 8.0)
	assert_almost_eq(lucian.current_move_speed(), base_speed + 60.0, 0.001)
	await wait_seconds(1.1)
	assert_almost_eq(lucian.current_move_speed(), base_speed, 0.001)


func test_w_itself_does_not_trigger_move_speed() -> void:
	_rank(Slot.W, 1)
	var base_speed := lucian.current_move_speed()
	dummy.add_mark(ArdentBlaze.MARK, 6.0)
	lucian.on_damage_dealt(dummy, DamageInfo.create(10.0, DamageInfo.Type.MAGIC, &"w", lucian), 8.0)
	assert_eq(lucian.current_move_speed(), base_speed)


func test_r_fires_22_shots_over_3_seconds() -> void:
	lucian.progress.set_level(6)
	_rank(Slot.R, 1)
	assert_true(lucian.try_cast(Slot.R, dummy.position))
	await wait_seconds(1.5)
	assert_between(hits.size(), 8, 14, "about half the shots after half the time")
	await wait_seconds(2.0)
	assert_eq(hits.size(), 22)
	assert_eq(_sources().filter(func(source: StringName) -> bool: return source != &"r"), [])
	assert_almost_eq(hits[0][1], (15.0 + 0.25 * lucian.stats.ad) * DUMMY_ARMOR_MULTIPLIER, 0.01)


func test_r_lets_lucian_move_and_e_but_blocks_q_w_and_attacks() -> void:
	lucian.progress.set_level(6)
	for slot in [Slot.Q, Slot.W, Slot.E, Slot.R]:
		_rank(slot, 1)
	lucian.try_cast(Slot.R, dummy.position)
	lucian.command_move(Vector2(0, 300))
	await wait_seconds(0.5)
	assert_gt(lucian.position.y, 100.0, "moves while firing")
	assert_false(lucian.try_cast(Slot.Q, dummy.position))
	assert_false(lucian.try_cast(Slot.W, dummy.position))
	lucian.command_attack(dummy)
	await wait_seconds(1.0)
	assert_does_not_have(_sources(), &"basic")
	assert_true(lucian.try_cast(Slot.E, Vector2(0, -400)))
	assert_true(lucian.skills[Slot.R].is_channeling(), "E does not stop R")


func test_pressing_r_again_stops_it() -> void:
	lucian.progress.set_level(6)
	_rank(Slot.R, 1)
	lucian.try_cast(Slot.R, dummy.position)
	await wait_seconds(0.5)
	assert_true(lucian.try_cast(Slot.R, dummy.position))
	assert_false(lucian.skills[Slot.R].is_channeling())
	var shots_so_far := hits.size()
	await wait_seconds(1.0)
	assert_lte(hits.size(), shots_so_far + 1, "at most one bullet was still in the air")
	assert_lt(hits.size(), 10)


func test_r_max_rank_pierces_with_falloff() -> void:
	var second := load("res://src/enemies/training_dummy.tscn").instantiate() as TrainingDummy
	second.position = Vector2(900, 0)
	add_child_autofree(second)
	var second_hits: Array[float] = []
	second.damage_taken.connect(func(_info: DamageInfo, final_amount: float) -> void: second_hits.append(final_amount))
	lucian.progress.set_level(16)
	_rank(Slot.R, 3)
	lucian.try_cast(Slot.R, dummy.position)
	await wait_seconds(0.6)
	assert_gt(second_hits.size(), 0, "bullets pierce through the first dummy")
	assert_almost_eq(second_hits[0], hits[0][1] * 0.85, 0.01)


func test_r_below_max_rank_stops_at_first_enemy() -> void:
	var second := load("res://src/enemies/training_dummy.tscn").instantiate() as TrainingDummy
	second.position = Vector2(900, 0)
	add_child_autofree(second)
	var second_hits: Array[float] = []
	second.damage_taken.connect(func(_info: DamageInfo, final_amount: float) -> void: second_hits.append(final_amount))
	lucian.progress.set_level(11)
	_rank(Slot.R, 2)
	lucian.try_cast(Slot.R, dummy.position)
	await wait_seconds(0.6)
	assert_eq(second_hits.size(), 0)

extends GutTest
## Act 4's boss, Dark Lucian (4-3): two-shot basic attacks, Piercing Light,
## Relentless Pursuit and The Culling. His skills are driven directly, as
## test_elder_dragon does.

## Where Lucian starts: away from the origin, where most tests put Dark
## Lucian, since a body put on top of his would be pushed out.
const LUCIAN_AT := Vector2(-3000, 0)
const E := &"relentless_pursuit"
const Q := &"piercing_light"
const R := &"the_culling"

var lucian: Lucian
## Warnings, shots, beams and trails go here, so they are freed with the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []
## Every enemy shot added to the effects, as it was launched: {source, info,
## direction, speed, reach, from}.
var launched: Array[Dictionary] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_dark_lucian_save_slot_")
	received.clear()
	launched.clear()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	effects = Node2D.new()
	add_child_autofree(effects)
	effects.child_entered_tree.connect(_on_effect_added)
	lucian.projectile_parent = effects
	# Set before he enters the tree, so his body starts there too.
	lucian.position = LUCIAN_AT
	add_child_autofree(lucian)
	lucian.damage_received.connect(func(info: DamageInfo, amount: float) -> void: received.append([info, amount]))


func after_each() -> void:
	get_tree().paused = false


func _on_effect_added(node: Node) -> void:
	if node is EnemyProjectile:
		var shot := node as EnemyProjectile
		launched.append({"source": shot.info.source, "info": shot.info, "direction": shot.direction,
			"speed": shot.speed, "reach": shot.max_range, "from": shot.position})


func _data() -> EnemyData:
	return load("res://data/enemies/dark_lucian.tres") as EnemyData


func _dark(at: Vector2) -> DarkLucian:
	var boss := DarkLucian.new()
	boss.setup(_data(), 4, 1, lucian)
	boss.position = at
	boss.projectile_parent = effects
	boss.warning_parent = effects
	add_child_autofree(boss)
	_quiet(boss)
	return boss


## No basic attacks, no skills of his own and no walking: the test drives him.
func _quiet(boss: Boss) -> void:
	boss._attack_left = 1000.0
	for id: StringName in boss._cooldowns:
		boss._cooldowns[id] = 1000.0
	boss.move_speed = 0.0


func _true(amount: float) -> DamageInfo:
	return DamageInfo.create(amount, DamageInfo.Type.TRUE, &"test")


## The live nodes of `type` among the effects.
func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


## Lucian's hits from `source`.
func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


## The shots launched with `source`.
func _launched(source: StringName) -> Array:
	return launched.filter(func(shot: Dictionary) -> bool: return shot.source == source)


func _wall(at: Vector2, wall_radius: float) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = Layers.WORLD
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = wall_radius
	shape.shape = circle
	wall.position = at
	wall.add_child(shape)
	add_child_autofree(wall)


func _is_side(direction: Vector2, toward: Vector2) -> bool:
	return direction.is_normalized() and is_zero_approx(direction.dot(toward))


# --- data and waves ---------------------------------------------------------


func test_dark_lucian_matches_the_table() -> void:
	var data := _data()
	assert_not_null(data)
	if data == null:
		return
	var fields := ["id", "kind", "behavior", "max_hp", "armor", "mr", "damage", "damage_type", "projectile_speed",
		"attack_range", "attack_interval", "move_speed", "radius", "purple_first", "purple_repeat", "gold", "xp"]
	var table := [&"dark_lucian", &"boss", &"dark_lucian", 18000.0, 45.0, 45.0, 40.0, DamageInfo.Type.PHYSICAL, 1400.0,
		550.0, 1.3, 330.0, 40.0, 10, 2, 300, 0]
	for i in fields.size():
		assert_eq(data.get(fields[i]), table[i], fields[i])
	assert_eq(data.display_name, "Dark Lucian")
	assert_not_null(data.art)
	if data.art:
		assert_eq(data.art.get_size(), Vector2(100, 100), "art size")
	assert_has(SaveGame.BOSS_IDS, "dark_lucian")


func test_he_is_the_boss_of_4_3_and_nowhere_else() -> void:
	assert_eq(WavePlan.boss("4-3"), &"dark_lucian")
	assert_eq(StageSetup.for_stage(SaveGame.instance(), 4, 3).boss, &"dark_lucian")
	for stage_id: String in WavePlan.STAGES:
		for wave: Array in WavePlan.waves(stage_id):
			assert_does_not_have(wave, &"dark_lucian", stage_id)


func test_his_skills_are_q_e_and_r_on_their_first_delays() -> void:
	var boss := DarkLucian.new()
	boss.setup(_data(), 4, 1, lucian)
	boss.projectile_parent = effects
	boss.warning_parent = effects
	boss.position = Vector2(3000, 0)
	add_child_autofree(boss)
	var ids := boss.skills.map(func(skill: Dictionary) -> StringName: return skill.id)
	assert_eq(ids.size(), 3, "no passive, no W")
	for id: StringName in [Q, E, R]:
		assert_has(ids, id)
	assert_eq(boss._cooldowns[Q], 3.0)
	assert_eq(boss._cooldowns[E], 0.0)
	assert_eq(boss._cooldowns[R], 0.0, "it waits for 80% HP instead")


# --- basic attack -------------------------------------------------------------


func test_a_basic_attack_is_two_40_physical_shots_at_1400_0_15_s_apart() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss._attack()
	assert_eq(_launched(&"basic").size(), 1, "the first gun at once")
	var first: EnemyProjectile = _effects(EnemyProjectile)[0]
	assert_eq(first.color, DarkLucian.SHOT_COLOR)
	await wait_seconds(0.1)
	assert_eq(_launched(&"basic").size(), 1, "the second waits")
	await wait_seconds(0.1)
	var shots := _launched(&"basic")
	assert_eq(shots.size(), 2, "the second gun 0.15 s later")
	for shot: Dictionary in shots:
		assert_eq(shot.speed, 1400.0)
		assert_eq(shot.reach, 550.0 + Boss.BOLT_OVERREACH)
		assert_almost_eq(shot.direction, Vector2.RIGHT, Vector2(0.01, 0.01), "at Lucian")
	var flying := _effects(EnemyProjectile)
	assert_eq(flying.size(), 2)
	if flying.size() == 2:
		assert_lt(flying[0].global_position.y * flying[1].global_position.y, 0.0, "one from each gun")
	var both: bool = await wait_until(func() -> bool: return _hits(&"basic").size() == 2, 1.0)
	assert_true(both, "both land")
	for hit: Array in _hits(&"basic"):
		assert_eq([hit[0].amount, hit[0].type, hit[0].from_skill], [40.0, DamageInfo.Type.PHYSICAL, false])
	await wait_seconds(0.5)
	assert_eq(_launched(&"basic").size(), 2, "two, no more")


func test_he_attacks_with_two_shots_every_1_3_s_on_his_own() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	boss._attack_left = 0.0
	await wait_seconds(0.4)
	assert_eq(_launched(&"basic").size(), 2)
	assert_almost_eq(boss._attack_left, 0.9, 0.1)


# --- Piercing Light (Q) ----------------------------------------------------


func test_piercing_light_warns_an_1100_by_70_line_for_0_7_s_then_a_dark_laser_hits_170_physical() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(0, 500)
	await wait_physics_frames(1)
	var busy := boss.piercing_light()
	assert_gt(busy, 0.7, "he stands while it warns")
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	if warnings.is_empty():
		return
	var warning: GroundWarning = warnings[0]
	assert_eq(warning.shape, GroundWarning.Shape.LINE)
	assert_eq(warning.reach, 1100.0)
	assert_eq(warning.width, 70.0)
	assert_almost_eq(warning.warn_time, 0.7, 0.0001)
	assert_almost_eq(warning.direction, Vector2.DOWN, Vector2(0.001, 0.001), "at Lucian")
	await wait_seconds(0.55)
	assert_eq(_hits(Q).size(), 0, "not before 0.7 s")
	assert_eq(_effects(LaserBeam).size(), 0, "no laser yet")
	var hit: bool = await wait_until(func() -> bool: return not _hits(Q).is_empty(), 0.4)
	assert_true(hit, "it hits")
	if not hit:
		return
	var info: DamageInfo = _hits(Q)[0][0]
	assert_eq([info.amount, info.type, info.from_skill], [170.0, DamageInfo.Type.PHYSICAL, true])
	var beams := _effects(LaserBeam)
	assert_eq(beams.size(), 1, "the dark laser along the line")
	if beams.size() == 1:
		var beam: LaserBeam = beams[0]
		assert_eq(beam.position, Vector2.ZERO)
		assert_almost_eq(beam.rotation, Vector2.DOWN.angle(), 0.001)
		assert_eq(beam.center_color, DarkLucian.LASER_CENTER, "dark, not Lucian's gold")
	await wait_seconds(0.3)
	assert_eq(_hits(Q).size(), 1, "once")


func test_piercing_light_misses_once_lucian_steps_out_of_the_line() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss.piercing_light()
	lucian.global_position = Vector2(500, 120)
	await wait_seconds(1.0)
	assert_eq(_hits(Q).size(), 0)


func test_he_casts_piercing_light_on_his_own_once_lucian_is_in_its_reach() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(1200, 0)
	boss._cooldowns[Q] = 0.0
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 0, "too far")
	lucian.global_position = Vector2(1000, 0)
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 1)
	assert_almost_eq(boss._cooldowns[Q], 7.0, 0.1)
	assert_gt(boss.busy_left, 0.0)


func test_a_dead_dark_lucian_fires_no_laser() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss.piercing_light()
	boss.take_damage(_true(99999.0))
	await wait_seconds(1.0)
	assert_eq(_hits(Q).size(), 0)
	assert_engine_error_count(0)


# --- Relentless Pursuit (E) -------------------------------------------------


func test_he_dodges_sideways_after_taking_6_percent_of_max_hp_within_1_5_s() -> void:
	var boss := _dark(Vector2.ZERO)
	boss._cooldowns[E] = 0.0
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	boss.take_damage(_true(1000.0))
	await wait_physics_frames(3)
	assert_false(boss.is_dashing(), "5.6% is not enough")
	boss.take_damage(_true(100.0))
	assert_almost_eq(boss.recent_damage(), 1100.0, 0.01, "recorded as it is taken")
	assert_false(boss.is_dashing(), "never inside the damage path")
	assert_false(boss.untargetable)
	await wait_physics_frames(1)
	assert_true(boss.is_dashing(), "on his next think")
	assert_true(boss.untargetable)
	assert_false(Lucian.is_target(boss))
	assert_false(boss.is_in_group(&"enemies"))
	assert_eq(boss.take_damage(_true(500.0)), 0.0, "nothing lands while he dashes")
	assert_almost_eq(boss._cooldowns[E], 6.0, 0.05)
	await wait_seconds(0.3)
	assert_false(boss.is_dashing(), "0.2 s")
	assert_false(boss.untargetable, "targetable again")
	assert_true(Lucian.is_target(boss))
	assert_true(boss.is_in_group(&"enemies"))
	assert_eq(boss.collision_layer, Layers.ENEMY_BODY)
	assert_almost_eq(absf(boss.global_position.y), 400.0, 2.0, "400 px")
	assert_almost_eq(boss.global_position.x, 0.0, 1.0, "across the line to Lucian")
	assert_engine_error_count(0)


func test_damage_spread_over_more_than_1_5_s_brings_no_dodge() -> void:
	var boss := _dark(Vector2.ZERO)
	boss._cooldowns[E] = 0.0
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	boss.take_damage(_true(700.0))
	await wait_seconds(1.6)
	boss.take_damage(_true(700.0))
	assert_almost_eq(boss.recent_damage(), 700.0, 0.01, "the first hit is forgotten")
	await wait_physics_frames(3)
	assert_false(boss.is_dashing())
	assert_eq(boss.global_position, Vector2.ZERO)


func test_a_real_shot_that_brings_him_to_6_percent_dodges_on_his_next_think() -> void:
	var boss := _dark(Vector2.ZERO)
	boss._cooldowns[E] = 0.0
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	# Damage inside area_entered, as an R bullet or a Rocketbelt bolt deals it.
	var shot := LinearProjectile.new()
	shot.launch(Vector2(-300, 0), Vector2.RIGHT, 2000.0, 600.0, 20.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(_true(1100.0)))
	effects.add_child(shot)
	var dashed: bool = await wait_until(func() -> bool: return boss.is_dashing(), 1.0)
	assert_true(dashed)
	var done: bool = await wait_until(func() -> bool: return not boss.is_dashing(), 0.5)
	assert_true(done)
	assert_false(boss.untargetable)
	assert_engine_error_count(0)


func test_a_homing_shot_in_flight_fizzles_when_he_dodges() -> void:
	var boss := _dark(Vector2.ZERO)
	boss._cooldowns[E] = 0.0
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	var shot := AttackProjectile.new()
	shot.launch(Vector2(-2000, 0), boss, _true(300.0))
	effects.add_child(shot)
	boss.take_damage(_true(1100.0))
	var hp := boss.hp
	await wait_physics_frames(2)
	assert_true(boss.is_dashing())
	assert_false(is_instance_valid(shot), "the shot in flight fizzles")
	await wait_seconds(0.8)
	assert_eq(boss.hp, hp, "it never lands")


func test_lucians_attack_order_on_him_survives_the_dash() -> void:
	lucian.global_position = Vector2.ZERO
	var boss := _dark(Vector2(480, 0))
	lucian.command_attack(boss)
	var shooting: bool = await wait_until(func() -> bool: return not _effects(AttackProjectile).is_empty(), 2.0)
	assert_true(shooting)
	if not shooting:
		return
	var shot: AttackProjectile = _effects(AttackProjectile)[0]
	boss._cooldowns[E] = 0.0
	boss.take_damage(_true(1100.0))
	var hp := boss.hp
	await wait_physics_frames(2)
	assert_true(boss.is_dashing(), "he dodges")
	assert_false(is_instance_valid(shot), "the shot in flight fizzles")
	assert_eq(lucian._order, Lucian.Order.ATTACK, "the order holds through the dash")
	assert_eq(lucian._target, boss)
	var landed: bool = await wait_until(func() -> bool: return not boss.is_dashing(), 0.5)
	assert_true(landed)
	assert_eq(boss.hp, hp)
	assert_eq(lucian._order, Lucian.Order.ATTACK, "still after it")
	assert_eq(lucian._target, boss)
	var hit_again: bool = await wait_until(func() -> bool: return boss.hp < hp, 2.5)
	assert_true(hit_again, "he follows and shoots again")
	assert_engine_error_count(0)


func test_he_dashes_at_lucian_when_he_is_more_than_750_away() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(700, 0)
	boss._cooldowns[E] = 0.0
	await wait_physics_frames(3)
	assert_false(boss.is_dashing(), "700 is close enough")
	lucian.global_position = Vector2(1000, 0)
	await wait_physics_frames(2)
	assert_true(boss.is_dashing(), "beyond 750")
	assert_true(boss.untargetable)
	await wait_seconds(0.3)
	assert_false(boss.is_dashing())
	assert_false(boss.untargetable)
	assert_almost_eq(boss.global_position, Vector2(400, 0), Vector2(2, 2), "400 px at him")
	assert_almost_eq(boss._cooldowns[E], 6.0 - 0.3, 0.1)


func test_a_wall_stops_the_dash() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(1000, 0)
	_wall(Vector2(250, 0), 60.0)
	await wait_physics_frames(1)
	boss.busy_left = boss.dash(Vector2.RIGHT)
	await wait_seconds(0.3)
	assert_false(boss.is_dashing())
	assert_lt(boss.global_position.x, 190.0, "stopped at the wall")
	assert_gt(boss.global_position.x, 100.0, "but he dashed")
	assert_false(boss.untargetable)


func test_the_dodge_takes_the_walkable_side() -> void:
	var map := StageMap.new()
	map.size = Vector2(2000, 2000)
	autofree(map)
	for i in 20:
		assert_almost_eq(DarkLucian.side_step(Vector2(1000, 100), Vector2.RIGHT, 400.0, map, 40.0), Vector2.DOWN, Vector2(0.001, 0.001), "away from the top edge")
		assert_almost_eq(DarkLucian.side_step(Vector2(1000, 1900), Vector2.RIGHT, 400.0, map, 40.0), Vector2.UP, Vector2(0.001, 0.001), "away from the bottom edge")
	var ups := 0
	for i in 40:
		var side := DarkLucian.side_step(Vector2(1000, 1000), Vector2.RIGHT, 400.0, map, 40.0)
		assert_true(_is_side(side, Vector2.RIGHT), "sideways")
		if side.y < 0.0:
			ups += 1
	assert_between(ups, 1, 39, "either side in the open")
	assert_true(_is_side(DarkLucian.side_step(Vector2.ZERO, Vector2.RIGHT, 400.0, null, 40.0), Vector2.RIGHT), "no map: either side")


func test_a_dodge_near_the_edge_goes_the_open_way() -> void:
	var map := StageMap.new()
	map.size = Vector2(4000, 4000)
	autofree(map)
	lucian.global_position = Vector2(1600, 100)
	var boss := _dark(Vector2(1000, 100))
	boss.arena = map
	boss._cooldowns[E] = 0.0
	await wait_physics_frames(1)
	boss.take_damage(_true(1100.0))
	var done: bool = await wait_until(func() -> bool: return boss._cooldowns[E] > 0.0 and not boss.is_dashing(), 1.0)
	assert_true(done)
	assert_almost_eq(boss.global_position, Vector2(1000, 500), Vector2(2, 2))


func test_killed_mid_dash_he_stays_dead_and_nothing_breaks() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(1000, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.dash(Vector2.DOWN)
	await wait_physics_frames(3)
	assert_eq(_effects(DashTrail).size(), 1, "a violet trail")
	# As the wave helpers do: targetable again, then a killing hit.
	boss.set_untargetable(false)
	boss.take_damage(_true(99999.0))
	assert_true(boss.dead)
	await wait_seconds(0.8)
	assert_eq(_effects(DashTrail).size(), 0, "the trail fades")
	assert_engine_error_count(0)


# --- The Culling (R) --------------------------------------------------------


func test_the_culling_waits_for_80_percent_hp() -> void:
	var boss := _dark(Vector2(3000, 0))
	assert_false(boss._can_use(R), "full HP")
	boss.hp = boss.max_hp * 0.81
	assert_false(boss._can_use(R))
	boss.hp = boss.max_hp * 0.8
	assert_true(boss._can_use(R))
	assert_true(boss._can_use(Q), "Q doesn't wait")


func test_he_uses_the_culling_on_his_own_at_80_percent() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	boss._cooldowns[R] = 0.0
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 0, "not at full HP")
	boss.hp = boss.max_hp * 0.8
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 1)
	assert_true(boss.is_culling())
	assert_almost_eq(boss._cooldowns[R], 20.0, 0.1)
	assert_gte(boss.busy_left, 3.7, "busy for the whole R")


func test_the_culling_warns_a_1200_by_120_line_then_fires_24_bullets_along_it_while_he_strafes() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	var busy := boss.the_culling()
	assert_almost_eq(busy, 3.8, 0.0001, "busy for the warning and the stream")
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	if warnings.is_empty():
		return
	var warning: GroundWarning = warnings[0]
	assert_eq(warning.shape, GroundWarning.Shape.LINE)
	assert_eq(warning.reach, 1200.0)
	assert_eq(warning.width, 120.0)
	assert_almost_eq(warning.warn_time, 0.8, 0.0001)
	assert_almost_eq(warning.direction, Vector2.RIGHT, Vector2(0.001, 0.001), "at Lucian")
	var strafe := boss.strafe_direction
	assert_true(_is_side(strafe, Vector2.RIGHT), "he strafes across the line")
	# The line stays where it was aimed.
	lucian.global_position = Vector2(-700, 0)
	await wait_seconds(0.7)
	assert_eq(_launched(R).size(), 0, "not during the warning")
	await wait_seconds(1.6)
	assert_between(_launched(R).size(), 11, 15, "one every 0.125 s")
	await wait_seconds(1.7)
	var bullets := _launched(R)
	assert_eq(bullets.size(), 24)
	assert_false(boss.is_culling(), "over after 3 s")
	var spread := false
	for bullet: Dictionary in bullets:
		var off := absf(Vector2.RIGHT.angle_to(bullet.direction))
		assert_lte(off, deg_to_rad(4.0) + 0.0001, "within 4° of the fixed line")
		spread = spread or off > 0.001
		assert_eq([bullet.info.amount, bullet.info.type, bullet.info.from_skill], [30.0, DamageInfo.Type.PHYSICAL, true])
		assert_eq(bullet.reach, 1200.0)
	assert_true(spread, "a random spread")
	if bullets.size() == 24:
		assert_gt(bullets[23].from.dot(strafe), bullets[0].from.dot(strafe) + 300.0, "fired as he strafes")
	assert_almost_eq(boss.global_position.dot(strafe), 450.0, 10.0, "3 s at 150 px/s")
	assert_almost_eq(boss.global_position.dot(Vector2.RIGHT), 0.0, 1.0, "only sideways")
	await wait_seconds(0.5)
	assert_eq(_launched(R).size(), 24, "no more")


func test_stepping_sideways_out_of_the_line_dodges_every_bullet() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.the_culling()
	# He steps across the line during the warning, away from the strafe.
	await wait_seconds(0.4)
	lucian.global_position = Vector2(500, 0) - boss.strafe_direction * 150.0
	await wait_seconds(3.8)
	assert_eq(_launched(R).size(), 24)
	assert_eq(_hits(R).size(), 0)


func test_standing_in_the_line_takes_bullets() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.the_culling()
	await wait_seconds(4.0)
	var hits := _hits(R)
	assert_gt(hits.size(), 0, "the stream runs over him")
	for hit: Array in hits:
		assert_eq([hit[0].amount, hit[0].type, hit[0].from_skill], [30.0, DamageInfo.Type.PHYSICAL, true])


func test_banshees_veil_blocks_a_culling_bullet() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.the_culling()
	await wait_seconds(1.2)
	assert_false(lucian.item_cooldown(&"banshees_veil").is_ready(), "the veil took the first bullet")


func test_the_culling_fires_on_its_own_timer_even_if_its_warning_is_gone() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(600, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.the_culling()
	# Clean-up code clearing the warnings' layer.
	_effects(GroundWarning)[0].free()
	await wait_seconds(4.0)
	assert_eq(_launched(R).size(), 24)
	assert_engine_error_count(0)


func test_killed_mid_stream_he_stops_firing() -> void:
	var boss := _dark(Vector2.ZERO)
	lucian.global_position = Vector2(-600, 0)
	await wait_physics_frames(1)
	boss.busy_left = boss.the_culling()
	await wait_seconds(1.5)
	boss.take_damage(_true(99999.0))
	var fired := _launched(R).size()
	assert_gt(fired, 0)
	await wait_seconds(1.0)
	assert_eq(_launched(R).size(), fired)
	assert_engine_error_count(0)


# --- on the dark lane --------------------------------------------------------


func _stage() -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 4, 3))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


## A shot that hits `enemy` for `amount` from inside area_entered.
func _shoot(stage: Stage, enemy: Enemy, amount: float) -> void:
	var shot := LinearProjectile.new()
	shot.launch(enemy.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(_true(amount)))
	stage.get_node("Projectiles").add_child(shot)


func test_the_boss_wave_brings_him_to_the_river_and_a_kill_pays_10_purple() -> void:
	var stage: Stage = await _stage()
	assert_true(stage.arena is DarkMidLaneMap)
	assert_eq(stage.run.boss, &"dark_lucian")
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	var boss := stage.boss_unit as DarkLucian
	assert_not_null(boss, "a DarkLucian")
	if boss == null:
		return
	assert_eq(boss.global_position, stage.arena.boss_point)
	assert_eq(boss.max_hp, 18000.0, "no scaling")
	assert_eq(boss.arena, stage.arena)
	assert_eq(boss.health_bar.size, EnemyUnit.BOSS_BAR)
	_quiet(boss)
	await wait_physics_frames(1)
	_shoot(stage, boss, 99999.0)
	await wait_physics_frames(3)
	assert_true(boss.dead)
	assert_true(stage.result.visible, "the stage is cleared")
	assert_has(stage.reward_lines, "+10 purple essence (first clear)")
	assert_engine_error_count(0)


func test_a_real_shot_dodge_on_the_dark_lane_lands_on_open_ground() -> void:
	var stage: Stage = await _stage()
	var map := stage.arena as MidLaneMap
	var boss := stage.spawn_enemy(&"dark_lucian", map.boss_point) as DarkLucian
	assert_not_null(boss)
	if boss == null:
		return
	_quiet(boss)
	boss._cooldowns[E] = 0.0
	# He thinks only while Lucian can be fought.
	stage.lucian.invulnerable = false
	stage.lucian.global_position = map.boss_point - map.along() * 500.0
	await wait_physics_frames(2)
	_shoot(stage, boss, 1100.0)
	var dashed: bool = await wait_until(func() -> bool: return boss.is_dashing(), 1.0)
	assert_true(dashed)
	var done: bool = await wait_until(func() -> bool: return not boss.is_dashing(), 0.5)
	assert_true(done)
	assert_true(map.is_walkable(boss.global_position, 30.0), "on open ground")
	assert_gt(boss.global_position.distance_to(map.boss_point), 300.0, "he got away")
	assert_false(boss.untargetable)
	assert_engine_error_count(0)

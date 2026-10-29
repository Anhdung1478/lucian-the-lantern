extends GutTest
## Act 3's boss, the Elder Dragon (3-5): Elder Breath, Sky Dive and Elder's
## Mark. Its skills are driven directly, as test_drakes does.

## Where Lucian starts: away from the origin, where most tests put the
## dragon, since a body put on top of his would be pushed out (his body only
## follows a later move once the physics catches up).
const LUCIAN_AT := Vector2(-3000, 0)

var lucian: Lucian
## Warnings, marks, shots and floating text go here, so they are freed with
## the test.
var effects: Node2D
## [DamageInfo, amount] per hit Lucian took.
var received: Array[Array] = []


func before_each() -> void:
	# Run alone (-gconfig=), the pre-run hook is skipped: never touch the real save.
	if SaveGame._instance == null or SaveGame._instance.prefix == SaveGame.DEFAULT_PREFIX:
		SaveGame._instance = SaveGame.new("user://test_elder_dragon_save_slot_")
	received.clear()
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	effects = Node2D.new()
	add_child_autofree(effects)
	lucian.projectile_parent = effects
	# Set before he enters the tree, so his body starts there too.
	lucian.position = LUCIAN_AT
	add_child_autofree(lucian)
	lucian.damage_received.connect(func(info: DamageInfo, amount: float) -> void: received.append([info, amount]))


func after_each() -> void:
	get_tree().paused = false


func _data() -> EnemyData:
	return load("res://data/enemies/elder_dragon.tres") as EnemyData


func _elder(at: Vector2) -> ElderDragon:
	var dragon := ElderDragon.new()
	dragon.setup(_data(), 3, 1, lucian)
	dragon.position = at
	dragon.projectile_parent = effects
	dragon.warning_parent = effects
	add_child_autofree(dragon)
	_quiet(dragon)
	return dragon


## No basic attacks, no skills of its own and no walking: the test drives it.
func _quiet(dragon: Boss) -> void:
	dragon._attack_left = 1000.0
	for id: StringName in dragon._cooldowns:
		dragon._cooldowns[id] = 1000.0
	dragon.move_speed = 0.0


## The live nodes of `type` among the effects.
func _effects(type: Variant) -> Array:
	return effects.get_children().filter(func(node: Node) -> bool: return is_instance_of(node, type) and not node.is_queued_for_deletion())


## Lucian's hits from `source`.
func _hits(source: StringName) -> Array:
	return received.filter(func(hit: Array) -> bool: return hit[0].source == source)


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


## Takes off as Boss._think would have it: busy for what sky_dive returns.
func _dive(dragon: ElderDragon) -> float:
	dragon.busy_left = dragon.sky_dive()
	return dragon.busy_left


## The mark the dragon just cast.
func _mark(dragon: ElderDragon) -> ElderMark:
	dragon.elder_mark()
	var marks := _effects(ElderMark)
	assert_eq(marks.size(), 1, "one mark")
	return marks[0] if marks.size() > 0 else null


# --- data and waves ---------------------------------------------------------


func test_the_elder_dragon_matches_the_table() -> void:
	var data := _data()
	assert_not_null(data)
	if data == null:
		return
	var fields := ["id", "kind", "behavior", "max_hp", "armor", "mr", "damage", "damage_type", "projectile_speed",
		"attack_range", "attack_interval", "move_speed", "radius", "purple_first", "purple_repeat", "gold"]
	var table := [&"elder_dragon", &"boss", &"elder_dragon", 16000.0, 50.0, 50.0, 70.0, DamageInfo.Type.MAGIC, 900.0,
		650.0, 1.5, 280.0, 84.0, 10, 2, 300]
	for i in fields.size():
		assert_eq(data.get(fields[i]), table[i], fields[i])
	assert_eq(data.display_name, "Elder Dragon")
	assert_not_null(data.art)
	if data.art:
		assert_eq(data.art.get_size(), Vector2(180, 180), "art size")
	assert_has(SaveGame.BOSS_IDS, "elder_dragon")


func test_it_is_the_boss_of_3_5_and_nowhere_else() -> void:
	assert_eq(WavePlan.boss("3-5"), &"elder_dragon")
	assert_eq(StageSetup.for_stage(SaveGame.instance(), 3, 5).boss, &"elder_dragon")
	for stage_id: String in WavePlan.STAGES:
		for wave: Array in WavePlan.waves(stage_id):
			assert_does_not_have(wave, &"elder_dragon", stage_id)


func test_its_skills_start_on_their_first_delays() -> void:
	var dragon := ElderDragon.new()
	dragon.setup(_data(), 3, 1, lucian)
	dragon.projectile_parent = effects
	dragon.warning_parent = effects
	dragon.position = Vector2(3000, 0)
	add_child_autofree(dragon)
	assert_eq(dragon._cooldowns[&"elder_breath"], 2.0)
	assert_eq(dragon._cooldowns[&"elder_mark"], 8.0)
	assert_eq(dragon._cooldowns[&"sky_dive"], 0.0, "it waits for 85% HP instead")


func test_the_shot_is_a_70_magic_bolt_at_900() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(300, 0)
	await wait_physics_frames(1)
	dragon._attack()
	var bolts := _effects(EnemyProjectile)
	assert_eq(bolts.size(), 1)
	if bolts.is_empty():
		return
	assert_eq(bolts[0].speed, 900.0)
	assert_eq(bolts[0].color, ElderDragon.ELDER)
	var hit: bool = await wait_until(func() -> bool: return not received.is_empty(), 2.0)
	assert_true(hit)
	assert_eq([received[0][0].amount, received[0][0].type, received[0][0].source], [70.0, DamageInfo.Type.MAGIC, &"basic"])


# --- Elder Breath -----------------------------------------------------------


func test_elder_breath_warns_a_90_degree_700_cone_for_a_second_then_hits_160_magic() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(0, 500)
	await wait_physics_frames(1)
	var busy := dragon.elder_breath()
	assert_gt(busy, 1.0, "it stands while it breathes")
	var warnings := _effects(GroundWarning)
	assert_eq(warnings.size(), 1)
	if warnings.is_empty():
		return
	var warning: GroundWarning = warnings[0]
	assert_eq(warning.shape, GroundWarning.Shape.CONE)
	assert_almost_eq(warning.spread, deg_to_rad(90.0), 0.0001)
	assert_eq(warning.reach, 700.0)
	assert_almost_eq(warning.warn_time, 1.0, 0.0001)
	assert_almost_eq(warning.direction, Vector2.DOWN, Vector2(0.001, 0.001), "at Lucian")
	assert_true(warning.covers(Vector2(380, 480)), "38 degrees off is inside")
	assert_false(warning.covers(Vector2(500, 300)), "59 degrees off is not")
	await wait_seconds(0.8)
	assert_eq(_hits(&"elder_breath").size(), 0, "not before the second is up")
	await wait_seconds(0.4)
	var breath := _hits(&"elder_breath")
	assert_eq(breath.size(), 1, "it hits")
	if breath.size() == 1:
		assert_eq([breath[0][0].amount, breath[0][0].type, breath[0][0].from_skill], [160.0, DamageInfo.Type.MAGIC, true])


func test_elder_breath_misses_once_lucian_leaves_the_cone() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(500, 0)
	await wait_physics_frames(1)
	dragon.elder_breath()
	lucian.global_position = Vector2(-300, 0)
	await wait_seconds(1.2)
	assert_eq(_hits(&"elder_breath").size(), 0)


func test_the_dragon_breathes_on_its_own_when_the_cone_reaches_lucian() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(900, 0)
	dragon._cooldowns[&"elder_breath"] = 0.0
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 0, "too far")
	lucian.global_position = Vector2(720, 0)
	await wait_physics_frames(2)
	assert_eq(_effects(GroundWarning).size(), 1, "his body is in reach")
	assert_almost_eq(dragon._cooldowns[&"elder_breath"], 8.0, 0.1)
	assert_gt(dragon.busy_left, 0.0)


# --- Sky Dive ---------------------------------------------------------------


func test_sky_dive_waits_for_85_percent_hp() -> void:
	var dragon := _elder(Vector2(3000, 0))
	assert_false(dragon._can_use(&"sky_dive"), "full HP")
	dragon.hp = dragon.max_hp * 0.86
	assert_false(dragon._can_use(&"sky_dive"))
	dragon.hp = dragon.max_hp * 0.85
	assert_true(dragon._can_use(&"sky_dive"))
	assert_true(dragon._can_use(&"elder_breath"), "the others don't wait")
	assert_true(dragon._can_use(&"elder_mark"))


func test_the_dragon_dives_on_its_own_at_85_percent() -> void:
	var dragon := _elder(Vector2(800, 0))
	dragon._cooldowns[&"sky_dive"] = 0.0
	await wait_physics_frames(2)
	assert_false(dragon.is_diving(), "not at full HP")
	dragon.hp = dragon.max_hp * 0.85
	await wait_physics_frames(2)
	assert_true(dragon.is_diving())
	assert_almost_eq(dragon._cooldowns[&"sky_dive"], 18.0, 0.1)
	assert_gte(dragon.busy_left, 3.5, "busy for the whole dive")


func test_sky_dive_takes_it_up_untargetable_and_unseen() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	assert_gte(_dive(dragon), 3.6, "busy for the whole dive")
	assert_true(dragon.is_diving())
	assert_true(dragon.untargetable)
	assert_false(Lucian.is_target(dragon))
	assert_false(dragon.is_in_group(&"enemies"))
	assert_eq(dragon.collision_layer, 0)
	assert_eq(dragon.take_damage(DamageInfo.create(500.0, DamageInfo.Type.TRUE, &"test")), 0.0)
	assert_true(dragon.is_alive(), "only hidden")
	await wait_seconds(0.5)
	assert_eq(dragon.visuals.modulate.a, 0.0, "its art has faded out")
	assert_eq(dragon.health_bar.modulate.a, 0.0, "and its health bar")


func test_its_shadow_follows_lucian_at_300_over_walls() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(1500, 0)
	_wall(Vector2(200, 0), 60.0)
	await wait_physics_frames(1)
	_dive(dragon)
	await wait_seconds(1.0)
	assert_almost_eq(dragon.global_position.x, 300.0, 30.0, "300 px a second, over the wall")
	assert_almost_eq(dragon.global_position.y, 0.0, 1.0)
	var at := dragon.global_position
	lucian.global_position = at + Vector2(0, 800)
	await wait_seconds(0.4)
	assert_gt(dragon.global_position.y, at.y + 80.0, "it turns after him")
	assert_almost_eq(dragon.global_position.x, at.x, 1.0)


func test_a_circle_warning_fills_where_the_shadow_stops_then_it_lands_with_a_hit_and_a_push() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	_dive(dragon)
	await wait_seconds(2.2)
	assert_eq(_effects(GroundWarning).size(), 0, "no warning while it follows")
	var warned: bool = await wait_until(func() -> bool: return _effects(GroundWarning).size() == 1, 0.6)
	assert_true(warned, "the landing's warning")
	if not warned:
		return
	var warning: GroundWarning = _effects(GroundWarning)[0]
	assert_eq(warning.shape, GroundWarning.Shape.CIRCLE)
	assert_eq(warning.reach, 260.0)
	assert_almost_eq(warning.warn_time, 1.2, 0.0001)
	var spot := warning.global_position
	assert_eq(dragon.global_position, spot, "on its shadow")
	assert_true(dragon.untargetable, "still up while it falls")
	# He steps inside the circle, off its middle.
	lucian.global_position = spot + Vector2(100, 0)
	await wait_seconds(0.3)
	assert_eq(dragon.global_position, spot, "the shadow has stopped")
	assert_eq(_hits(&"sky_dive").size(), 0, "not yet")
	await wait_seconds(0.5)
	assert_eq(_hits(&"sky_dive").size(), 0, "still falling at 0.8 s")
	var hit: bool = await wait_until(func() -> bool: return not _hits(&"sky_dive").is_empty(), 1.0)
	assert_true(hit, "it lands on him")
	if not hit:
		return
	var landing: Array = _hits(&"sky_dive")[0]
	assert_eq([landing[0].amount, landing[0].type, landing[0].from_skill], [240.0, DamageInfo.Type.MAGIC, true])
	assert_false(dragon.is_diving())
	assert_false(dragon.untargetable, "targetable again")
	assert_true(Lucian.is_target(dragon))
	assert_true(dragon.is_in_group(&"enemies"))
	assert_eq(dragon.collision_layer, Layers.ENEMY_BODY)
	assert_eq(dragon.visuals.modulate.a, 1.0, "seen again")
	assert_eq(dragon.health_bar.modulate.a, 1.0)
	await wait_seconds(0.35)
	assert_almost_eq(lucian.global_position, spot + Vector2(300, 0), Vector2(6, 6), "pushed 200 away from the middle")
	assert_eq(_hits(&"sky_dive").size(), 1, "it lands once")
	assert_gt(dragon.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"test")), 0.0, "it can be hit")


func test_up_for_about_3_6_seconds() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(2000, 0)
	await wait_physics_frames(1)
	_dive(dragon)
	await wait_seconds(3.4)
	assert_true(dragon.untargetable, "up at 3.4 s")
	await wait_seconds(0.4)
	assert_false(dragon.untargetable, "down by 3.8 s")


func test_the_landing_misses_lucian_outside_the_circle() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	_dive(dragon)
	var warned: bool = await wait_until(func() -> bool: return _effects(GroundWarning).size() == 1, 3.0)
	assert_true(warned)
	var spot := dragon.global_position
	lucian.global_position = spot + Vector2(400, 0)
	await wait_seconds(1.4)
	assert_eq(_hits(&"sky_dive").size(), 0)
	assert_eq(lucian.global_position, spot + Vector2(400, 0), "no push")
	assert_false(dragon.untargetable, "it lands all the same")


func test_it_lands_on_its_own_timer_even_if_its_warning_is_gone() -> void:
	var dragon := _elder(Vector2.ZERO)
	lucian.global_position = Vector2(400, 0)
	await wait_physics_frames(1)
	_dive(dragon)
	var warned: bool = await wait_until(func() -> bool: return _effects(GroundWarning).size() == 1, 3.0)
	assert_true(warned)
	if not warned:
		return
	var spot := dragon.global_position
	lucian.global_position = spot + Vector2(100, 0)
	# Clean-up code clearing the warnings' layer mid-fall.
	_effects(GroundWarning)[0].free()
	var landed: bool = await wait_until(func() -> bool: return not dragon.is_diving(), 1.6)
	assert_true(landed, "it lands all the same")
	assert_false(dragon.untargetable)
	assert_true(Lucian.is_target(dragon))
	assert_eq(dragon.visuals.modulate.a, 1.0, "seen again")
	assert_eq(dragon.health_bar.modulate.a, 1.0)
	assert_eq(dragon.global_position, spot, "where it fell")
	assert_eq(_hits(&"sky_dive").size(), 1, "the hit still lands on him in the circle")
	await wait_seconds(0.3)
	assert_eq(_hits(&"sky_dive").size(), 1, "once")
	assert_engine_error_count(0)


func test_the_boss_bar_keeps_it_through_the_dive() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	var dragon := _elder(Vector2(400, 0))
	await wait_physics_frames(1)
	bar._process(0.0)
	assert_eq(bar.boss, dragon)
	_dive(dragon)
	bar._process(0.0)
	assert_eq(bar.boss, dragon, "held while it is up")
	assert_true(bar.visible)


func test_lucians_attack_order_holds_through_the_dive_and_he_shoots_once_it_lands() -> void:
	# The landing would push him, and a push drops his orders.
	lucian.invulnerable = true
	lucian.global_position = Vector2.ZERO
	var dragon := _elder(Vector2(560, 0))
	dragon.hp = dragon.max_hp * 0.8
	lucian.command_attack(dragon)
	var shooting: bool = await wait_until(func() -> bool: return not _effects(AttackProjectile).is_empty(), 2.0)
	assert_true(shooting)
	if not shooting:
		return
	var shot: AttackProjectile = _effects(AttackProjectile)[0]
	var hp := dragon.hp
	_dive(dragon)
	await wait_physics_frames(2)
	assert_false(is_instance_valid(shot), "the shot in flight fizzles")
	assert_eq(dragon.hp, hp)
	await wait_seconds(1.5)
	assert_eq(_effects(AttackProjectile).size(), 0, "no shots at it while it is up")
	assert_eq(lucian._order, Lucian.Order.ATTACK, "the order holds")
	assert_eq(lucian._target, dragon)
	assert_eq(dragon.hp, hp)
	var landed: bool = await wait_until(func() -> bool: return not dragon.untargetable, 3.0)
	assert_true(landed)
	var hit_again: bool = await wait_until(func() -> bool: return dragon.hp < hp, 2.0)
	assert_true(hit_again, "he shoots again once it lands")
	assert_engine_error_count(0)


func test_a_landing_spot_on_a_rock_moves_toward_the_pit_middle() -> void:
	var pit := DragonPitMap.new()
	autofree(pit)
	var middle := pit.boss_point
	var rock := Vector2(pit.wall_circles[0].x, pit.wall_circles[0].y)
	var spot := ElderDragon.landing_spot(rock, pit, 84.0)
	assert_true(pit.is_walkable(spot, 84.0), "the body fits")
	assert_lt(spot.distance_to(middle), rock.distance_to(middle), "toward the middle")
	assert_almost_eq(middle.direction_to(spot), middle.direction_to(rock), Vector2(0.001, 0.001), "straight in")
	assert_lt(spot.distance_to(rock), 84.0 + DragonPitMap.ROCK_RADIUS + 60.0, "no farther than it needs")
	var rim := middle + Vector2(0, DragonPitMap.FLOOR_RADIUS - 20.0)
	spot = ElderDragon.landing_spot(rim, pit, 84.0)
	assert_true(pit.is_walkable(spot, 84.0), "in from the rim")
	var open := middle + Vector2(300, 400)
	assert_eq(ElderDragon.landing_spot(open, pit, 84.0), open, "open ground stays")
	assert_eq(ElderDragon.landing_spot(rock, null, 84.0), rock, "no map, no change")


# --- Elder's Mark -----------------------------------------------------------


func test_elders_mark_lands_130_true_damage_after_4_seconds() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	var busy := dragon.elder_mark()
	assert_lt(busy, 0.5, "a quick cast")
	var marks := _effects(ElderMark)
	assert_eq(marks.size(), 1)
	if marks.is_empty():
		return
	var mark: ElderMark = marks[0]
	assert_eq(mark.lucian, lucian)
	assert_almost_eq(mark.time_left, 4.0, 0.0001)
	await wait_seconds(3.7)
	assert_eq(_hits(&"elder_mark").size(), 0, "not yet")
	var hit: bool = await wait_until(func() -> bool: return not _hits(&"elder_mark").is_empty(), 0.6)
	assert_true(hit)
	if not hit:
		return
	var info: DamageInfo = _hits(&"elder_mark")[0][0]
	assert_eq([info.amount, info.type, info.from_skill], [130.0, DamageInfo.Type.TRUE, true])
	assert_eq(_hits(&"elder_mark")[0][1], 130.0, "true damage: nothing lowers it")
	assert_true(not is_instance_valid(mark) or mark.is_queued_for_deletion(), "gone once it lands")


func test_the_mark_stays_over_lucian_with_its_ring() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	var mark := _mark(dragon)
	if mark == null:
		return
	lucian.global_position = Vector2(-300, 200)
	await wait_physics_frames(2)
	assert_eq(mark.global_position, lucian.global_position, "it follows him")
	assert_gt(mark.z_index, 0, "drawn over the units")
	assert_eq(mark.get_parent(), effects, "on the warnings' layer")
	await wait_seconds(1.0)
	assert_almost_eq(mark.progress(), 0.25, 0.05, "the ring counts down")


func test_the_mark_deals_3_times_as_much_under_25_percent_hp() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	var mark := _mark(dragon)
	if mark == null:
		return
	# What counts is his HP when it lands.
	lucian.hp = lucian.stats.max_hp * 0.2
	mark.time_left = 0.1
	await wait_seconds(0.3)
	var hits := _hits(&"elder_mark")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq(hits[0][1], 390.0, "130 x 3")


func test_the_mark_deals_130_at_25_percent_or_more() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	lucian.hp = lucian.stats.max_hp * 0.1
	var mark := _mark(dragon)
	if mark == null:
		return
	lucian.hp = lucian.stats.max_hp * 0.3
	mark.time_left = 0.1
	await wait_seconds(0.3)
	var hits := _hits(&"elder_mark")
	assert_eq(hits.size(), 1)
	if hits.size() == 1:
		assert_eq(hits[0][1], 130.0, "healed in time")


func test_a_shield_absorbs_the_mark() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	lucian.add_shield(&"barrier", 200.0, 10.0)
	var shield := lucian.total_shield()
	var mark := _mark(dragon)
	if mark == null:
		return
	mark.time_left = 0.1
	await wait_seconds(0.3)
	assert_eq(_hits(&"elder_mark").size(), 1)
	assert_eq(lucian.hp, lucian.stats.max_hp, "the shield took it all")
	assert_almost_eq(lucian.total_shield(), shield - 130.0, 0.01)


func test_banshees_veil_blocks_the_mark() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	var mark := _mark(dragon)
	if mark == null:
		return
	mark.time_left = 0.1
	await wait_seconds(0.3)
	assert_eq(_hits(&"elder_mark").size(), 0, "blocked whole")
	assert_eq(lucian.hp, lucian.stats.max_hp)
	assert_false(lucian.item_cooldown(&"banshees_veil").is_ready(), "the veil is spent")
	assert_true(not is_instance_valid(mark) or mark.is_queued_for_deletion())


func test_the_mark_goes_away_if_lucian_is_in_stasis() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	var mark := _mark(dragon)
	if mark == null:
		return
	lucian.enter_stasis(0.5, 200.0, 0.0)
	await wait_physics_frames(2)
	assert_true(not is_instance_valid(mark) or mark.is_queued_for_deletion(), "gone")
	await wait_seconds(4.0)
	assert_eq(_hits(&"elder_mark").size(), 0)


func test_the_mark_goes_away_if_the_dragon_dies() -> void:
	var dragon := _elder(Vector2(600, 0))
	await wait_physics_frames(1)
	var mark := _mark(dragon)
	if mark == null:
		return
	dragon.take_damage(DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test"))
	await wait_physics_frames(2)
	assert_true(not is_instance_valid(mark) or mark.is_queued_for_deletion(), "gone with the dragon")
	await wait_seconds(0.6)
	assert_eq(_hits(&"elder_mark").size(), 0)


func test_the_dragon_marks_on_its_own() -> void:
	var dragon := _elder(Vector2(1500, 0))
	dragon._cooldowns[&"elder_mark"] = 0.0
	await wait_physics_frames(2)
	assert_eq(_effects(ElderMark).size(), 1, "wherever he is")
	assert_almost_eq(dragon._cooldowns[&"elder_mark"], 16.0, 0.1)


# --- in the pit ---------------------------------------------------------------


func _stage() -> Stage:
	SaveGame.instance().reset()
	var stage: Stage = load("res://src/stage/stage.tscn").instantiate()
	stage.setup(StageSetup.for_stage(SaveGame.instance(), 3, 5))
	add_child_autofree(stage)
	await wait_process_frames(2)
	stage.lucian.invulnerable = true
	return stage


## A shot that hits `enemy` for `amount` from inside area_entered, as an R
## bullet or a Rocketbelt bolt does.
func _shoot(stage: Stage, enemy: Enemy, amount: float) -> void:
	var shot := LinearProjectile.new()
	shot.launch(enemy.global_position, Vector2.RIGHT, 0.0, 100.0, 30.0)
	shot.hit_enemy.connect(func(hit: Enemy, _prior: int) -> void: hit.take_damage(DamageInfo.create(amount, DamageInfo.Type.TRUE, &"test")))
	stage.get_node("Projectiles").add_child(shot)


func _boss_wave(stage: Stage) -> ElderDragon:
	stage.jump_to_boss_wave()
	stage.runner.tick(0.1)
	stage.runner.tick(0.1)
	return stage.boss_unit as ElderDragon


## A quiet dragon in the middle of the pit, outside the waves: its death
## doesn't end the stage (the result would pause the tree).
func _pit_dragon(stage: Stage) -> ElderDragon:
	var dragon := stage.spawn_enemy(&"elder_dragon", stage.arena.boss_point) as ElderDragon
	assert_not_null(dragon)
	if dragon:
		_quiet(dragon)
	return dragon


func test_the_boss_wave_lands_it_in_the_middle_of_the_pit_and_a_kill_pays_10_purple() -> void:
	var stage: Stage = await _stage()
	assert_eq(stage.run.boss, &"elder_dragon")
	var dragon := _boss_wave(stage)
	assert_not_null(dragon, "an ElderDragon")
	if dragon == null:
		return
	assert_eq(dragon.global_position, stage.arena.boss_point)
	assert_eq(dragon.max_hp, 16000.0, "no scaling")
	assert_eq(dragon.arena, stage.arena)
	assert_eq(dragon.health_bar.size, EnemyUnit.BOSS_BAR)
	_quiet(dragon)
	await wait_physics_frames(1)
	_shoot(stage, dragon, 99999.0)
	await wait_physics_frames(3)
	assert_true(dragon.dead)
	assert_true(stage.result.visible, "the stage is cleared")
	assert_has(stage.reward_lines, "+10 purple essence (first clear)")
	assert_engine_error_count(0)


func test_a_dragon_killed_mid_dive_never_lands_and_nothing_breaks() -> void:
	var stage: Stage = await _stage()
	var dragon := _pit_dragon(stage)
	if dragon == null:
		return
	stage.lucian.invulnerable = false
	var hits: Array[DamageInfo] = []
	stage.lucian.damage_received.connect(func(info: DamageInfo, _amount: float) -> void: hits.append(info))
	stage.lucian.global_position = dragon.global_position + Vector2(0, 200)
	await wait_physics_frames(1)
	_dive(dragon)
	await wait_seconds(2.6)
	var warnings := stage.get_node("Warnings").get_children().filter(func(node: Node) -> bool: return node is GroundWarning)
	assert_eq(warnings.size(), 1, "falling")
	# As the wave helpers do: targetable again, then a killing shot.
	dragon.set_untargetable(false)
	_shoot(stage, dragon, 99999.0)
	await wait_physics_frames(3)
	assert_true(dragon.dead, "killed mid-dive")
	await wait_seconds(1.2)
	assert_eq(hits.filter(func(info: DamageInfo) -> bool: return info.source == &"sky_dive").size(), 0, "it never lands")
	assert_engine_error_count(0)


func test_the_stage_closing_mid_dive_breaks_nothing() -> void:
	var stage: Stage = await _stage()
	var dragon := _pit_dragon(stage)
	if dragon == null:
		return
	await wait_physics_frames(1)
	_dive(dragon)
	dragon.elder_mark()
	await wait_seconds(1.0)
	stage.queue_free()
	await wait_seconds(3.0)
	assert_engine_error_count(0)


func test_a_dive_in_the_pit_lands_clear_of_the_rocks() -> void:
	var stage: Stage = await _stage()
	var dragon := _pit_dragon(stage)
	if dragon == null:
		return
	var rock := Vector2(stage.arena.wall_circles[0].x, stage.arena.wall_circles[0].y)
	# Lucian on the rock's far side, where the shadow ends on the rock.
	dragon.global_position = rock + Vector2(-200, 0)
	stage.lucian.global_position = rock + Vector2(130, 0)
	await wait_physics_frames(1)
	_dive(dragon)
	var landed: bool = await wait_until(func() -> bool: return not dragon.is_diving(), 5.0)
	assert_true(landed)
	assert_true(stage.arena.is_walkable(dragon.global_position, dragon.radius), "on open ground")
	assert_lt(dragon.global_position.distance_to(stage.arena.boss_point), DragonPitMap.FLOOR_RADIUS, "inside the pit")
	assert_engine_error_count(0)

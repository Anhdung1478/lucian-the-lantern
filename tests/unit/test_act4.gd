extends GutTest
## Act 4's shadow minions: the Act 1-2 minions in dark art, with Act 4's scaling.

const SHADOW_IDS := ["shadow_melee_minion", "shadow_ranged_minion", "shadow_siege_minion", "shadow_super_minion"]
const LIGHT_IDS := ["melee_minion", "ranged_minion", "siege_minion", "super_minion"]

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func _minion(id: String, at: Vector2, act := 4, wave := 1) -> Minion:
	var minion := Minion.new()
	minion.setup(load("res://data/enemies/%s.tres" % id), act, wave, lucian)
	minion.position = at
	add_child_autofree(minion)
	return minion


func test_shadow_minions_copy_the_light_ones_numbers() -> void:
	for i in SHADOW_IDS.size():
		var shadow: EnemyData = load("res://data/enemies/%s.tres" % SHADOW_IDS[i])
		var light: EnemyData = load("res://data/enemies/%s.tres" % LIGHT_IDS[i])
		assert_eq(shadow.id, StringName(SHADOW_IDS[i]))
		assert_ne(shadow.display_name, light.display_name)
		assert_true(shadow.display_name.begins_with("Shadow "), shadow.display_name)
		assert_eq(shadow.kind, light.kind)
		assert_eq(shadow.behavior, light.behavior)
		assert_eq(shadow.camp, &"")
		assert_ne(shadow.art, light.art)
		for prop in ["max_hp", "armor", "mr", "damage", "attack_range", "attack_interval", "move_speed", "radius",
				"gold", "xp", "damage_type", "keep_min", "keep_max", "projectile_speed", "area_radius", "warn_time", "empower_radius"]:
			assert_eq(shadow.get(prop), light.get(prop), "%s %s" % [SHADOW_IDS[i], prop])


func test_a_shadow_ranged_minion_keeps_its_distance_and_fires() -> void:
	var minion := _minion("shadow_ranged_minion", Vector2(200, 0))
	var before := lucian.hp
	await wait_seconds(2.5)
	assert_between(minion.global_position.distance_to(lucian.global_position), 400.0, 560.0)
	assert_lt(lucian.hp, before)


func test_a_shadow_siege_minion_drops_a_shell_warning() -> void:
	_minion("shadow_siege_minion", Vector2(600, 0))
	var seen := false
	for i in 240:
		await wait_physics_frames(1)
		for node in get_children():
			if node is GroundWarning:
				seen = true
		if seen:
			break
	assert_true(seen)


func test_a_shadow_super_minion_empowers_shadow_melee_and_ranged_not_siege() -> void:
	_minion("shadow_super_minion", Vector2(1500, 0))
	var melee := _minion("shadow_melee_minion", Vector2(1700, 0))
	var ranged := _minion("shadow_ranged_minion", Vector2(1500, 300))
	var siege := _minion("shadow_siege_minion", Vector2(1500, -300))
	await wait_physics_frames(3)
	assert_true(melee.has_status(EnemyUnit.EMPOWER))
	assert_true(ranged.has_status(EnemyUnit.EMPOWER))
	assert_false(siege.has_status(EnemyUnit.EMPOWER))


func test_act_4_scaling() -> void:
	var minion := _minion("shadow_melee_minion", Vector2(2000, 0), 4, 1)
	assert_almost_eq(minion.max_hp, 240.0 * 2.8, 0.01)
	assert_almost_eq(minion.damage, 12.0 * 1.75, 0.01)
	var data: EnemyData = load("res://data/enemies/shadow_melee_minion.tres")
	assert_almost_eq(data.reward_scale(4), 1.75, 0.001)
	var reward := KillRewards.roll(data, 4, StageSetup.new(), RandomNumberGenerator.new())
	assert_eq(reward.gold, roundi(60 * 1.75))
	assert_eq(reward.xp, roundi(30 * 1.75))
	assert_eq(reward.blue, 4)

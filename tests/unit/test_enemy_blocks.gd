extends GutTest
## Phase 8's enemy building blocks on lone units: summons and their cap,
## vanish, the freed fade, leaps, charges, the veil and the tint, and an
## enemy shot that misses. The stage side of summons and vanish is in
## test_stage_waves.gd.

const MAP_SIZE := Vector2(3000, 2000)
## A wall 80 wide standing across the middle of the small map.
const WALL := [Vector2(1460, 400), Vector2(1540, 400), Vector2(1540, 1600), Vector2(1460, 1600)]

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	lucian.position = Vector2(2000, 0)
	add_child_autofree(lucian)


func _data(id := &"test_unit") -> EnemyData:
	var data := EnemyData.new()
	data.id = id
	data.max_hp = 500.0
	data.damage = 10.0
	data.radius = 28.0
	data.move_speed = 300.0
	data.gold = 40
	data.xp = 20
	return data


func _unit(data: EnemyData, at := Vector2.ZERO) -> EnemyUnit:
	var unit := EnemyUnit.new()
	unit.setup(data, 1, 1, lucian)
	unit.position = at
	add_child_autofree(unit)
	return unit


func _summoner(every: float, count: int, cap: int) -> EnemyData:
	var data := _data(&"test_summoner")
	data.summon_id = WavePlan.MELEE
	data.summon_every = every
	data.summon_count = count
	data.summon_cap = cap
	return data


func _lethal() -> DamageInfo:
	return DamageInfo.create(99999.0, DamageInfo.Type.TRUE, &"test")


## A small open map with WALL, plus `chasm` as abyss when given.
func _map(chasm := PackedVector2Array()) -> StageMap:
	var map := StageMap.new()
	map.size = MAP_SIZE
	map.wall_polygons.append(PackedVector2Array(WALL))
	if not chasm.is_empty():
		map.chasm_polygons.append(chasm)
	add_child_autofree(map)
	return map


# --- Summons -------------------------------------------------------------


func test_new_data_fields_default_to_nothing() -> void:
	var data := EnemyData.new()
	assert_eq(data.tint, Color.WHITE)
	assert_false(data.perch)
	assert_eq(data.summon_id, &"")
	assert_eq(data.summon_every, 0.0)
	assert_eq(data.summon_count, 0)
	assert_eq(data.summon_cap, 0)
	assert_false(data.frees)


func test_a_summoner_asks_for_its_count_each_period_and_never_past_its_cap() -> void:
	var unit := _unit(_summoner(0.1, 2, 3))
	var asked: Array[Dictionary] = []
	unit.summon_requested.connect(func(from: EnemyUnit, id: StringName, at: Vector2) -> void:
		asked.append({"from": from, "id": id, "gap": at.distance_to(from.global_position)}))
	await wait_physics_frames(3)
	assert_eq(asked.size(), 0, "not before its first period")
	await wait_physics_frames(6)
	assert_eq(asked.size(), 2, "its count at once")
	assert_eq(unit.summons, 2)
	await wait_physics_frames(40)
	assert_eq(asked.size(), 3, "the cap holds: 2, then 1")
	assert_eq(unit.summons, 3)
	for request in asked:
		assert_eq(request.from, unit)
		assert_eq(request.id, WavePlan.MELEE)
		assert_almost_eq(request.gap, unit.radius + EnemyUnit.SUMMON_GAP, 0.5, "beside it")
	unit.summon_gone()
	assert_eq(unit.summons, 2)
	await wait_physics_frames(12)
	assert_eq(asked.size(), 4, "a summon gone makes room for one")
	await wait_physics_frames(12)
	assert_eq(asked.size(), 4)


func test_a_summoner_that_cannot_fight_calls_nothing() -> void:
	lucian.invulnerable = true
	var unit := _unit(_summoner(0.1, 2, 6))
	var asked := [0]
	unit.summon_requested.connect(func(_from: EnemyUnit, _id: StringName, _at: Vector2) -> void: asked[0] += 1)
	await wait_physics_frames(20)
	assert_eq(asked[0], 0)
	lucian.invulnerable = false
	await wait_physics_frames(9)
	assert_eq(asked[0], 2, "its period counts from when the fight is on")


func test_no_summon_id_means_no_summons() -> void:
	var data := _summoner(0.05, 2, 6)
	data.summon_id = &""
	var unit := _unit(data)
	var asked := [0]
	unit.summon_requested.connect(func(_from: EnemyUnit, _id: StringName, _at: Vector2) -> void: asked[0] += 1)
	await wait_physics_frames(20)
	assert_eq(asked[0], 0)


# --- Vanish and the freed fade -------------------------------------------


func test_vanish_is_an_escape_with_no_note() -> void:
	var unit := _unit(_data())
	assert_eq(unit.escape_note, "Escaped!")
	watch_signals(unit)
	unit.vanish()
	assert_true(unit.has_escaped)
	assert_false(unit.is_alive())
	assert_false(unit.is_in_group(&"enemies"))
	assert_eq(unit.escape_note, "")
	assert_signal_emit_count(unit, "escaped", 1)
	assert_signal_not_emitted(unit, "died")
	unit.vanish()
	assert_signal_emit_count(unit, "escaped", 1, "once")


func test_a_freeing_enemy_rises_brightens_and_fades_up() -> void:
	var data := _data()
	data.frees = true
	var unit := _unit(data)
	await wait_physics_frames(1)
	unit.take_damage(_lethal())
	await wait_physics_frames(20)
	assert_true(is_instance_valid(unit), "a slower fade than the grey one")
	assert_lt(unit.visuals.position.y, -5.0, "it rises")
	assert_gt(unit.sprite.modulate.g, 1.0, "brighter")
	assert_gt(unit.sprite.modulate.g, unit.sprite.modulate.r, "teal-white")
	assert_lt(unit.modulate.a, 1.0, "fading")
	await wait_seconds(EnemyUnit.FREED_TIME)
	assert_false(is_instance_valid(unit), "then it goes")


func test_a_vanished_freeing_enemy_is_freed_too() -> void:
	var data := _data()
	data.frees = true
	var unit := _unit(data)
	await wait_physics_frames(1)
	unit.vanish()
	await wait_physics_frames(20)
	assert_lt(unit.visuals.position.y, -5.0)


func test_other_enemies_keep_the_grey_fade() -> void:
	var unit := _unit(_data())
	await wait_physics_frames(1)
	unit.take_damage(_lethal())
	await wait_physics_frames(10)
	assert_eq(unit.visuals.position, Vector2.ZERO)
	assert_eq(unit.sprite.modulate, Color.WHITE)


func test_the_freed_chime_is_its_own_sound() -> void:
	var chime := Sfx.stream(&"freed")
	assert_ne(chime.data.size(), Sfx.stream(&"test_no_such_sound").data.size(), "not the fallback beep")


# --- Leaps and charges ---------------------------------------------------


func test_a_leap_lands_where_it_was_aimed_untargetable_in_the_air() -> void:
	lucian.global_position = Vector2(100, 0)
	var unit := _unit(_data())
	await wait_physics_frames(1)
	var landed: Array[Vector2] = []
	unit.landed.connect(func() -> void: landed.append(unit.global_position))
	var hp := lucian.hp
	unit._attack_left = 0.0
	unit.leap_to(Vector2(37.5, 21.25), 0.5)
	assert_true(unit.is_leaping())
	assert_true(unit.untargetable)
	assert_false(unit.is_in_group(&"enemies"))
	await wait_physics_frames(15)
	assert_gt(unit.visuals.scale.x, 1.1, "high in the arc")
	assert_eq(lucian.hp, hp, "no attack from the air, though Lucian is in reach")
	assert_eq(landed.size(), 0)
	await wait_physics_frames(20)
	assert_eq(landed, [Vector2(37.5, 21.25)] as Array[Vector2], "exactly where it was aimed, once")
	assert_false(unit.is_leaping())
	assert_false(unit.untargetable)
	assert_true(unit.is_in_group(&"enemies"))
	assert_eq(unit.visuals.scale, Vector2.ONE)
	await wait_physics_frames(3)
	assert_lt(lucian.hp, hp, "it fights again once down")


func test_a_leap_crosses_a_wall() -> void:
	_map()
	lucian.global_position = Vector2(2600, 1800)
	lucian.invulnerable = true
	var unit := _unit(_data(), Vector2(1300, 1000))
	await wait_physics_frames(1)
	unit.leap_to(Vector2(1700, 1000), 0.3)
	await wait_physics_frames(25)
	assert_eq(unit.global_position, Vector2(1700, 1000))


func test_a_charge_runs_its_distance_through_lucian_and_hits_him_once() -> void:
	lucian.global_position = Vector2(300, 0)
	var unit := _unit(_data())
	await wait_physics_frames(1)
	var hits := [0]
	var landed: Array[Vector2] = []
	unit.landed.connect(func() -> void: landed.append(unit.global_position))
	var mask := unit.collision_mask
	var start := unit.global_position
	unit.charge(Vector2.RIGHT, 600.0, 1200.0, func() -> void: hits[0] += 1)
	assert_true(unit.is_charging())
	assert_eq(unit.collision_mask, Layers.WORLD | Layers.CHASM, "through units, not walls or the abyss")
	await wait_physics_frames(45)
	assert_false(unit.is_charging())
	assert_eq(hits[0], 1, "Lucian is hit once")
	assert_eq(landed.size(), 1)
	assert_almost_eq(landed[0], start + Vector2(600, 0), Vector2(1, 1), "the whole distance, through him")
	assert_eq(unit.collision_mask, mask, "its walking mask is back")


func test_a_charge_stops_at_a_wall() -> void:
	_map()
	lucian.global_position = Vector2(2600, 1800)
	lucian.invulnerable = true
	var unit := _unit(_data(), Vector2(1100, 1000))
	await wait_physics_frames(1)
	var landed := [0]
	unit.landed.connect(func() -> void: landed[0] += 1)
	unit.charge(Vector2.RIGHT, 1000.0, 1500.0)
	await wait_physics_frames(60)
	assert_eq(landed[0], 1)
	assert_false(unit.is_charging())
	assert_lt(unit.global_position.x, 1460.0 - unit.radius * 0.85 + 2.0, "short of the wall")
	assert_gt(unit.global_position.x, 1300.0, "it ran up to it")


func test_a_charge_stops_at_the_abyss() -> void:
	_map(PackedVector2Array([Vector2(700, 300), Vector2(900, 300), Vector2(900, 1700), Vector2(700, 1700)]))
	lucian.global_position = Vector2(2600, 1800)
	lucian.invulnerable = true
	var unit := _unit(_data(), Vector2(300, 1000))
	await wait_physics_frames(1)
	unit.charge(Vector2.RIGHT, 1000.0, 1500.0)
	await wait_physics_frames(60)
	assert_false(unit.is_charging())
	assert_lt(unit.global_position.x, 700.0 - unit.radius * 0.85 + 2.0, "short of the abyss")
	assert_gt(unit.global_position.x, 500.0)


func test_no_thinking_while_charging() -> void:
	lucian.global_position = Vector2(60, 0)
	var unit := _unit(_data())
	await wait_physics_frames(1)
	var hp := lucian.hp
	unit._attack_left = 0.0
	unit.charge(Vector2.DOWN, 300.0, 300.0)
	await wait_physics_frames(10)
	assert_eq(lucian.hp, hp, "no attack while it charges")


# --- Perched (a ledge in the abyss) --------------------------------------


## A perched unit stands inside the abyss's shape: it never walks (a walk
## would push its body out of it), but still faces Lucian and attacks.
func test_a_perched_unit_never_walks_but_faces_and_attacks() -> void:
	_map(PackedVector2Array([Vector2(900, 900), Vector2(1100, 900), Vector2(1100, 1100), Vector2(900, 1100)]))
	lucian.global_position = Vector2(2200, 1000)
	var data := _data()
	data.attack_interval = 0.2
	var unit := _unit(data, Vector2(1000, 1000))
	assert_false(unit.perched, "not by default")
	unit.perched = true
	await wait_physics_frames(20)
	assert_eq(unit.global_position, Vector2(1000, 1000), "Lucian out of reach: it stays")
	unit.walk(Vector2.RIGHT, 0.1)
	unit.walk_toward(Vector2(1800, 1000), 0.1)
	assert_eq(unit.global_position, Vector2(1000, 1000), "walk and walk_toward do nothing")
	lucian.global_position = Vector2(1000, 1135)
	var hp := lucian.hp
	await wait_physics_frames(20)
	assert_lt(lucian.hp, hp, "in reach, it attacks")
	assert_almost_eq(unit.visuals.rotation, PI / 2.0, 0.01, "facing him")
	assert_eq(unit.global_position, Vector2(1000, 1000))


# --- The veil and the tint -----------------------------------------------


func test_the_tint_colors_the_sprite() -> void:
	var data := _data()
	data.tint = Color(0.6, 1.0, 0.7)
	var unit := _unit(data)
	assert_eq(unit.sprite.modulate, Color(0.6, 1.0, 0.7))
	assert_eq(unit.visuals.modulate, Color.WHITE, "the hit flash keeps visuals")


func test_a_veiled_enemy_is_a_dark_silhouette_with_no_health_bar() -> void:
	var data := _data()
	data.tint = Color(0.6, 1.0, 0.7)
	var unit := _unit(data)
	unit.veiled = true
	var shade := unit.sprite.modulate
	assert_lt(shade.get_luminance(), 0.2, "dark")
	assert_false(unit.health_bar.visible)
	assert_true(unit.is_in_group(&"enemies"), "still a target")
	# A hit flash tweens visuals; the veil lives on the sprite.
	unit.take_damage(DamageInfo.create(10.0, DamageInfo.Type.TRUE, &"test"))
	await wait_seconds(0.25)
	assert_eq(unit.sprite.modulate, shade, "a flash never lifts the veil")
	assert_eq(unit.visuals.modulate, Color.WHITE)
	unit.veiled = false
	assert_eq(unit.sprite.modulate, Color(0.6, 1.0, 0.7), "its tint is back")
	assert_true(unit.health_bar.visible)


func test_a_unit_veiled_before_it_is_ready_starts_dark() -> void:
	var unit := EnemyUnit.new()
	unit.setup(_data(), 1, 1, lucian)
	unit.veiled = true
	add_child_autofree(unit)
	assert_lt(unit.sprite.modulate.get_luminance(), 0.2)
	assert_false(unit.health_bar.visible)


# --- Enemy shots that miss -----------------------------------------------


func _bolt(toward: Vector2, reach: float, from_skill := false) -> EnemyProjectile:
	var info := DamageInfo.create(30.0, DamageInfo.Type.MAGIC, &"test")
	info.from_skill = from_skill
	var bolt := EnemyProjectile.new()
	bolt.launch(Vector2.ZERO, toward, info, lucian)
	bolt.speed = 1500.0
	bolt.max_range = reach
	return bolt


## Counts `bolt`'s missed and hit_lucian, then adds it.
func _fly(bolt: EnemyProjectile) -> Dictionary:
	var counts := {"missed": 0, "hit": 0}
	bolt.missed.connect(func() -> void: counts.missed += 1)
	bolt.hit_lucian.connect(func() -> void: counts.hit += 1)
	add_child_autofree(bolt)
	return counts


func test_a_shot_that_reaches_its_range_misses() -> void:
	lucian.global_position = Vector2(300, 300)
	var counts := _fly(_bolt(Vector2.RIGHT, 400.0))
	await wait_physics_frames(30)
	assert_eq(counts.missed, 1)
	assert_eq(counts.hit, 0)


func test_a_shot_that_hits_a_wall_misses() -> void:
	_map()
	lucian.global_position = Vector2(2000, 1000)
	var bolt := _bolt(Vector2.RIGHT, 2000.0)
	bolt.launch(Vector2(1100, 1000), Vector2.RIGHT, bolt.info, lucian)
	var counts := _fly(bolt)
	await wait_physics_frames(30)
	assert_false(is_instance_valid(bolt), "the wall stopped it")
	assert_eq(counts.missed, 1)
	assert_eq(counts.hit, 0)


func test_a_shot_that_hits_lucian_does_not_miss() -> void:
	lucian.global_position = Vector2(300, 0)
	var counts := _fly(_bolt(Vector2.RIGHT, 600.0))
	await wait_physics_frames(30)
	assert_eq(counts.hit, 1)
	assert_eq(counts.missed, 0)


func test_a_shot_banshees_veil_blocks_is_not_a_miss() -> void:
	lucian.inventory.put(Inventory.EQUIP_START, lucian.item_catalog.find(&"banshees_veil"))
	lucian.global_position = Vector2(300, 0)
	var hp := lucian.hp
	var counts := _fly(_bolt(Vector2.RIGHT, 600.0, true))
	await wait_physics_frames(30)
	assert_eq(lucian.hp, hp, "the veil took it")
	assert_false(lucian.item_cooldown(&"banshees_veil").is_ready(), "the veil was spent")
	assert_eq(counts.hit, 0)
	assert_eq(counts.missed, 0, "it reached him: no miss")


func test_a_boomerang_misses_only_when_it_never_touched_him_on_the_way_out() -> void:
	var thrower := Node2D.new()
	add_child_autofree(thrower)
	lucian.global_position = Vector2(300, 300)
	var wide := _bolt(Vector2.RIGHT, 400.0)
	wide.return_to = thrower
	var wide_counts := _fly(wide)
	await wait_physics_frames(60)
	assert_false(is_instance_valid(wide), "back home")
	assert_eq(wide_counts.missed, 1, "out and back without touching him: one miss")
	lucian.global_position = Vector2(300, 0)
	var true_throw := _bolt(Vector2.RIGHT, 400.0)
	true_throw.return_to = thrower
	var true_counts := _fly(true_throw)
	await wait_physics_frames(60)
	assert_gt(true_counts.hit, 0)
	assert_eq(true_counts.missed, 0, "it touched him on the way out")

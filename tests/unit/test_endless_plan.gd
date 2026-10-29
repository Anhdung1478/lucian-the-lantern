extends GutTest
## Endless mode's waves, strength and maps (EndlessPlan): the design's
## "Waves", "Strength" and map tables.

var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 7


## The pool entry (an enemy id, or a pack's id) each enemy id comes from.
func _pool_entries(pool: Array[StringName]) -> Dictionary:
	var entries := {}
	for id in pool:
		for member: StringName in WavePlan.PACKS.get(id, [id]):
			entries[member] = id
	return entries


func test_every_pool_id_loads_and_has_its_pools_kind() -> void:
	var pools := {&"normal": EndlessPlan.NORMALS, &"elite": EndlessPlan.ELITES, &"mini_boss": EndlessPlan.MINI_BOSSES, &"boss": EndlessPlan.BOSSES}
	for kind: StringName in pools:
		var pool: Array[StringName] = pools[kind]
		assert_false(pool.is_empty(), String(kind))
		for member: StringName in _pool_entries(pool):
			var path := Stage.ENEMY_PATH % member
			assert_true(ResourceLoader.exists(path), String(member))
			if ResourceLoader.exists(path):
				assert_eq((load(path) as EnemyData).kind, kind, String(member))


func test_the_pools_follow_the_design() -> void:
	assert_eq(EndlessPlan.NORMALS.size(), 12)
	for pack in [&"raptors", &"wolves", &"krugs", &"gromp"]:
		assert_has(EndlessPlan.NORMALS, pack)
	assert_eq(EndlessPlan.ELITES.size(), 11)
	assert_eq(EndlessPlan.MINI_BOSSES, [&"infernal_drake", &"ocean_drake", &"maokai", &"elise", &"karthus_revived", &"hecarim"] as Array[StringName])
	assert_eq(EndlessPlan.BOSSES, [&"akshan", &"elder_dragon", &"dark_lucian", &"karthus", &"thresh_final"] as Array[StringName])


func test_which_waves_have_a_boss_or_a_mini_boss() -> void:
	for w in [10, 20, 30, 100]:
		assert_true(EndlessPlan.is_boss_wave(w), "boss %d" % w)
		assert_false(EndlessPlan.is_mini_boss_wave(w), "mini boss %d" % w)
	for w in [5, 15, 25, 95]:
		assert_true(EndlessPlan.is_mini_boss_wave(w), "mini boss %d" % w)
		assert_false(EndlessPlan.is_boss_wave(w), "boss %d" % w)
	for w in [0, 1, 4, 7, 11, 19]:
		assert_false(EndlessPlan.is_boss_wave(w), "boss %d" % w)
		assert_false(EndlessPlan.is_mini_boss_wave(w), "mini boss %d" % w)


func test_wave_5_ends_with_a_mini_boss() -> void:
	for s in 20:
		rng.seed = s
		var ids := EndlessPlan.wave(5, rng)
		assert_has(EndlessPlan.MINI_BOSSES, ids.back(), "seed %d" % s)
		var bosses := ids.filter(func(id: StringName) -> bool: return id in EndlessPlan.MINI_BOSSES or id in EndlessPlan.BOSSES)
		assert_eq(bosses.size(), 1, "seed %d: one mini boss, no boss" % s)


func test_wave_10_is_one_boss_alone() -> void:
	for w in [10, 20, 30]:
		var ids := EndlessPlan.wave(w, rng)
		assert_eq(ids.size(), 1, "wave %d" % w)
		assert_has(EndlessPlan.BOSSES, ids[0], "wave %d" % w)


func test_wave_7_has_neither() -> void:
	for s in 20:
		rng.seed = s
		for id in EndlessPlan.wave(7, rng):
			assert_false(id in EndlessPlan.MINI_BOSSES or id in EndlessPlan.BOSSES, "seed %d: %s" % [s, id])


func test_a_boss_never_repeats_the_last_one() -> void:
	var last := &""
	for i in 200:
		var id := EndlessPlan.pick_boss(rng, last)
		assert_ne(id, last)
		last = id
	for w in range(10, 210, 10):
		var id: StringName = EndlessPlan.wave(w, rng, 1, last)[0]
		assert_ne(id, last, "wave %d" % w)
		last = id


func test_a_mini_boss_never_repeats_the_last_one() -> void:
	var last := &""
	for i in 200:
		var id := EndlessPlan.pick_mini_boss(rng, last)
		assert_ne(id, last)
		last = id
	for w in range(5, 205, 10):
		var id: StringName = EndlessPlan.wave(w, rng, 1, &"", last).back()
		assert_ne(id, last, "wave %d" % w)
		last = id


func test_thresh_1_is_never_picked_and_every_other_boss_can_be() -> void:
	assert_does_not_have(EndlessPlan.BOSSES, &"thresh_1")
	var seen := {}
	var last := &""
	for i in 500:
		last = EndlessPlan.pick_boss(rng, last)
		seen[last] = true
	assert_false(seen.has(&"thresh_1"))
	assert_eq(seen.size(), EndlessPlan.BOSSES.size())


func test_the_counts_follow_the_formula_and_are_capped() -> void:
	assert_eq(EndlessPlan.normal_count(1), 9)
	assert_eq(EndlessPlan.normal_count(21), 29)
	assert_eq(EndlessPlan.normal_count(22), 30)
	assert_eq(EndlessPlan.normal_count(80), 30)
	assert_eq(EndlessPlan.elite_count(3), 0)
	assert_eq(EndlessPlan.elite_count(4), 1)
	assert_eq(EndlessPlan.elite_count(15), 3)
	assert_eq(EndlessPlan.elite_count(16), 4)
	assert_eq(EndlessPlan.elite_count(80), 4)


## Each wave: exactly elite_count elites, and normal_count normal enemies of
## 2 kinds. A pack comes whole, so 2 packs can leave it up to 2 short.
func test_wave_sizes_follow_the_formula() -> void:
	var normals := _pool_entries(EndlessPlan.NORMALS)
	var exact := 0
	for s in 10:
		rng.seed = s
		for w in range(1, 46):
			if EndlessPlan.is_boss_wave(w):
				continue
			var ids := EndlessPlan.wave(w, rng)
			if EndlessPlan.is_mini_boss_wave(w):
				ids.pop_back()
			var kinds := {}
			var normal := 0
			var elite := 0
			for id in ids:
				if normals.has(id):
					normal += 1
					kinds[normals[id]] = true
				elif id in EndlessPlan.ELITES:
					elite += 1
				else:
					fail_test("wave %d: %s is in no pool" % [w, id])
			var label := "seed %d, wave %d" % [s, w]
			assert_eq(elite, EndlessPlan.elite_count(w), label)
			assert_eq(kinds.size(), 2, label)
			assert_between(normal, EndlessPlan.normal_count(w) - 2, EndlessPlan.normal_count(w), label)
			if kinds.keys().any(func(id: StringName) -> bool: return not WavePlan.PACKS.has(id) or WavePlan.PACKS[id].size() == 1):
				assert_eq(normal, EndlessPlan.normal_count(w), "%s: a single kind fills it" % label)
				exact += 1
	assert_gt(exact, 0)


func test_modifier_2_doubles_the_elites_up_to_8() -> void:
	assert_eq(EndlessPlan.elite_count(4, 2), 2)
	assert_eq(EndlessPlan.elite_count(16, 2), 8)
	assert_eq(EndlessPlan.elite_count(80, 2), 8)
	var elites := EndlessPlan.wave(16, rng, 2).filter(func(id: StringName) -> bool: return id in EndlessPlan.ELITES)
	assert_eq(elites.size(), 8)


func test_the_same_seed_gives_the_same_waves() -> void:
	var first := []
	for w in range(1, 16):
		first.append(EndlessPlan.wave(w, rng))
	rng.seed = 7
	for w in range(1, 16):
		assert_eq(EndlessPlan.wave(w, rng), first[w - 1], "wave %d" % w)


## The design's Strength table: w1 ×1, w10 ×2.2, w35 ×8.2 (more than Act 6's
## last wave's ×7.6). Damage: (1 + 0.025(w−1)) × (1 + 0.05(w−1)).
func test_normal_and_elite_strength_follow_the_table() -> void:
	assert_eq(EndlessPlan.hp_scale(1), 1.0)
	assert_eq(EndlessPlan.damage_scale(1), 1.0)
	assert_almost_eq(EndlessPlan.hp_scale(10), 2.233, 0.001)
	assert_almost_eq(EndlessPlan.hp_scale(35), 8.208, 0.001)
	var melee: EnemyData = load(Stage.ENEMY_PATH % &"melee_minion")
	assert_almost_eq(melee.hp_scale(6, 7), 7.6, 0.001, "Act 6's last wave")
	assert_gt(EndlessPlan.hp_scale(35), melee.hp_scale(6, 7))
	assert_almost_eq(EndlessPlan.damage_scale(10), 1.225 * 1.45, 0.001)
	assert_almost_eq(EndlessPlan.damage_scale(35), 1.85 * 2.7, 0.001)


## Fixed by wave: 15000 (a boss) or 9000 (a mini boss) × (1 + 0.3(k−1)), and
## damage × (1 + 0.15(k−1)), with k = w / 10 for a boss, (w + 5) / 10 for a
## mini boss.
func test_boss_and_mini_boss_strength_follow_the_table() -> void:
	assert_eq(EndlessPlan.boss_hp(10), 15000.0)
	assert_almost_eq(EndlessPlan.boss_hp(20), 19500.0, 0.01)
	assert_almost_eq(EndlessPlan.boss_hp(30), 24000.0, 0.01)
	assert_eq(EndlessPlan.mini_boss_hp(5), 9000.0)
	assert_almost_eq(EndlessPlan.mini_boss_hp(15), 11700.0, 0.01)
	assert_almost_eq(EndlessPlan.mini_boss_hp(25), 14400.0, 0.01)
	assert_eq(EndlessPlan.boss_power(10), 1.0)
	assert_almost_eq(EndlessPlan.boss_power(20), 1.15, 0.0001)
	assert_almost_eq(EndlessPlan.boss_power(40), 1.45, 0.0001)
	assert_eq(EndlessPlan.mini_boss_power(5), 1.0)
	assert_almost_eq(EndlessPlan.mini_boss_power(15), 1.15, 0.0001)
	assert_almost_eq(EndlessPlan.mini_boss_power(35), 1.45, 0.0001)


func test_a_boss_called_up_early_is_never_weaker_than_its_first_tier() -> void:
	assert_eq(EndlessPlan.boss_hp(3), EndlessPlan.BOSS_HP)
	assert_eq(EndlessPlan.mini_boss_hp(1), EndlessPlan.MINI_BOSS_HP)
	assert_eq(EndlessPlan.boss_power(0), 1.0)
	assert_eq(EndlessPlan.hp_scale(0), 1.0)


func test_rewards_pay_like_an_act_every_10_waves() -> void:
	assert_eq(EndlessPlan.reward_act(1), 1)
	assert_eq(EndlessPlan.reward_act(10), 1)
	assert_eq(EndlessPlan.reward_act(11), 2)
	assert_eq(EndlessPlan.reward_act(35), 4)


func test_the_map_table() -> void:
	assert_eq(EndlessPlan.map_for(1), Vector2i(1, 1), "Mid lane")
	assert_eq(EndlessPlan.map_for(2), Vector2i(2, 3), "Training ground: the ring of pillars")
	assert_eq(EndlessPlan.map_for(3), Vector2i(3, 4), "Jungle: water and Honeyfruit")
	assert_eq(EndlessPlan.map_for(4), Vector2i(4, 1), "Dark mid lane")
	assert_eq(EndlessPlan.map_for(5), Vector2i(5, 3), "Dead forest: mist banks and the nest")
	assert_eq(EndlessPlan.map_for(6), Vector2i(6, 1), "Thresh's domain")
	for choice in range(1, 7):
		assert_eq(EndlessPlan.map_for(choice).x, choice, "choice i is act i")
		assert_eq(EndlessPlan.map_name(choice), Journey.ENDLESS_MAPS[choice])
	assert_eq(EndlessPlan.map_name(EndlessPlan.RANDOM), "Random")


func test_random_rolls_each_real_map() -> void:
	var seen := {}
	for s in 100:
		rng.seed = s
		var choice := EndlessPlan.resolve_map(EndlessPlan.RANDOM, rng)
		assert_between(choice, 1, 6)
		seen[choice] = true
	assert_eq(seen.size(), 6)
	for choice in range(1, 7):
		assert_eq(EndlessPlan.resolve_map(choice, rng), choice)

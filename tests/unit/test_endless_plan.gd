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


## P10: each pool id's act, the first whose story brings it.
func test_every_pool_id_has_the_act_of_its_story() -> void:
	var acts := {
		&"melee_minion": 1, &"ranged_minion": 1, &"siege_minion": 1, &"super_minion": 2, &"akshan": 2,
		&"raptors": 3, &"wolves": 3, &"krugs": 3, &"gromp": 3, &"blue_sentinel": 3, &"red_brambleback": 3, &"rift_scuttler": 3,
		&"infernal_drake": 3, &"ocean_drake": 3, &"elder_dragon": 3,
		&"shadow_melee_minion": 4, &"shadow_ranged_minion": 4, &"shadow_siege_minion": 4, &"shadow_super_minion": 4, &"dark_lucian": 4,
		&"sapling": 5, &"spiderling": 5, &"maiden_of_the_mist": 5, &"broodmother": 5, &"maokai": 5, &"elise": 5, &"karthus": 5,
		&"mist_walker": 6, &"lantern_soul": 6, &"spectral_rider": 6, &"chain_warden": 6, &"karthus_revived": 6, &"hecarim": 6, &"thresh_final": 6,
	}
	var pools: Array[StringName] = EndlessPlan.NORMALS + EndlessPlan.ELITES + EndlessPlan.MINI_BOSSES + EndlessPlan.BOSSES
	assert_eq(pools.size(), acts.size(), "every pool id is listed here")
	for id in pools:
		assert_eq(EndlessPlan.act_of(id), acts.get(id, -1), String(id))
	assert_eq(EndlessPlan.act_of(&"thresh_1"), 1)
	assert_eq(EndlessPlan.act_of(&"teemo"), 0, "in no story stage")


## P10: Endless opens after Act 3, so Acts 1–3 are the least it draws from,
## and they leave enough of each to pick from.
func test_the_pools_of_acts_1_to_3() -> void:
	for acts in [0, 1, 3]:
		assert_eq(EndlessPlan.cleared_pool(EndlessPlan.NORMALS, acts), [&"melee_minion", &"ranged_minion", &"raptors", &"wolves", &"krugs", &"gromp"] as Array[StringName], "%d acts" % acts)
		assert_eq(EndlessPlan.cleared_pool(EndlessPlan.ELITES, acts), [&"siege_minion", &"super_minion", &"blue_sentinel", &"red_brambleback", &"rift_scuttler"] as Array[StringName])
		assert_eq(EndlessPlan.cleared_pool(EndlessPlan.MINI_BOSSES, acts), [&"infernal_drake", &"ocean_drake"] as Array[StringName])
		assert_eq(EndlessPlan.cleared_pool(EndlessPlan.BOSSES, acts), [&"akshan", &"elder_dragon"] as Array[StringName])
	assert_eq(EndlessPlan.cleared_pool(EndlessPlan.BOSSES, 4), [&"akshan", &"elder_dragon", &"dark_lucian"] as Array[StringName])
	assert_eq(EndlessPlan.cleared_pool(EndlessPlan.NORMALS, 6), EndlessPlan.NORMALS)
	assert_eq(EndlessPlan.cleared_pool(EndlessPlan.BOSSES, 6), EndlessPlan.BOSSES)


func test_waves_draw_only_from_the_acts_cleared() -> void:
	var entries := _pool_entries(EndlessPlan.NORMALS + EndlessPlan.ELITES + EndlessPlan.MINI_BOSSES + EndlessPlan.BOSSES)
	for acts in [3, 4, 5]:
		var seen := {}
		for s in 10:
			rng.seed = s
			var last_boss := &""
			var last_mini_boss := &""
			for w in range(1, 61):
				var ids := EndlessPlan.wave(w, rng, 1, last_boss, last_mini_boss, acts)
				if EndlessPlan.is_boss_wave(w):
					last_boss = ids[0]
				elif EndlessPlan.is_mini_boss_wave(w):
					last_mini_boss = ids.back()
				for id in ids:
					var act := EndlessPlan.act_of(entries[id])
					seen[act] = true
					assert_between(act, 1, acts, "%d acts, wave %d: %s" % [acts, w, id])
		assert_eq(seen.size(), acts, "%d acts: each of them comes" % acts)


## P10: with Acts 1–3 only, the bosses take turns: Akshan, the Elder Dragon.
func test_two_bosses_or_mini_bosses_still_never_repeat() -> void:
	var last := &""
	var seen := {}
	for i in 50:
		var id := EndlessPlan.pick_boss(rng, last, 3)
		assert_ne(id, last)
		assert_has([&"akshan", &"elder_dragon"], id)
		seen[id] = true
		last = id
	assert_eq(seen.size(), 2)
	last = &""
	for w in range(5, 205, 10):
		var id: StringName = EndlessPlan.wave(w, rng, 1, &"", last, 3).back()
		assert_ne(id, last, "wave %d" % w)
		assert_has([&"infernal_drake", &"ocean_drake"], id)
		last = id


## P10: Acts 5–6's bosses and mini bosses deal ×0.8 at tier 1, ×0.9 at
## tier 2, then all their power; the others always all of it.
func test_late_bosses_and_mini_bosses_deal_less_at_tiers_1_and_2() -> void:
	assert_almost_eq(EndlessPlan.boss_power(10, &"karthus"), EndlessPlan.boss_power(10) * 0.8, 0.0001)
	assert_almost_eq(EndlessPlan.boss_power(20, &"thresh_final"), EndlessPlan.boss_power(20) * 0.9, 0.0001)
	assert_almost_eq(EndlessPlan.boss_power(30, &"karthus"), EndlessPlan.boss_power(30), 0.0001)
	assert_almost_eq(EndlessPlan.mini_boss_power(5, &"maokai"), EndlessPlan.mini_boss_power(5) * 0.8, 0.0001)
	assert_almost_eq(EndlessPlan.mini_boss_power(15, &"hecarim"), EndlessPlan.mini_boss_power(15) * 0.9, 0.0001)
	assert_almost_eq(EndlessPlan.mini_boss_power(25, &"elise"), EndlessPlan.mini_boss_power(25), 0.0001)
	for id in [&"akshan", &"elder_dragon", &"dark_lucian"]:
		assert_almost_eq(EndlessPlan.boss_power(10, id), EndlessPlan.boss_power(10), 0.0001, String(id))
	assert_almost_eq(EndlessPlan.mini_boss_power(5, &"infernal_drake"), EndlessPlan.mini_boss_power(5), 0.0001)


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
	assert_almost_eq(melee.hp_scale(6, 7), 3.6, 0.001, "Act 6's last wave")
	assert_gt(EndlessPlan.hp_scale(35), melee.hp_scale(6, 7))
	assert_almost_eq(EndlessPlan.damage_scale(10), 1.225 * 1.45, 0.001)
	assert_almost_eq(EndlessPlan.damage_scale(35), 1.85 * 2.7, 0.001)


## Fixed by wave: 15000 (a boss) or 9000 (a mini boss) × (1 + 0.3(k−1)),
## with k = w / 10 for a boss, (w + 5) / 10 for a mini boss. P9: a boss has
## at least 0.6 of the HP the wave before it brings, which wins from wave 20
## (it was 19500, 24000 and 33000 at waves 20, 30 and 50).
func test_boss_and_mini_boss_hp_follow_the_table() -> void:
	assert_eq(EndlessPlan.boss_hp(10), 15000.0, "tier 1: more than 0.6 × wave 9's 12078")
	assert_almost_eq(EndlessPlan.boss_hp(20), 0.6 * EndlessPlan.wave_hp(19), 0.01)
	assert_almost_eq(EndlessPlan.boss_hp(20), 24118.9, 0.1)
	assert_almost_eq(EndlessPlan.boss_hp(30), 41713.6, 0.1)
	assert_almost_eq(EndlessPlan.boss_hp(50), 85554.3, 0.1)
	assert_eq(EndlessPlan.mini_boss_hp(5), 9000.0)
	assert_almost_eq(EndlessPlan.mini_boss_hp(15), 11700.0, 0.01)
	assert_almost_eq(EndlessPlan.mini_boss_hp(25), 14400.0, 0.01)


## P9: × (1 + 0.15(k−1)), or the square root of the wave's normal damage
## scale when that is more, which it is at every boss and mini boss wave (it
## was ×1, ×1.15 and ×1.45 at waves 10, 20 and 40, and at waves 5, 15 and 35).
func test_boss_and_mini_boss_damage_keeps_up_with_the_waves() -> void:
	for w in [10, 20, 40]:
		assert_almost_eq(EndlessPlan.boss_power(w), sqrt(EndlessPlan.damage_scale(w)), 0.0001, "boss %d" % w)
	assert_almost_eq(EndlessPlan.boss_power(10), 1.3328, 0.0001)
	assert_almost_eq(EndlessPlan.boss_power(20), 1.6960, 0.0001)
	assert_almost_eq(EndlessPlan.boss_power(40), 2.4138, 0.0001)
	for w in [5, 15, 35]:
		assert_almost_eq(EndlessPlan.mini_boss_power(w), sqrt(EndlessPlan.damage_scale(w)), 0.0001, "mini boss %d" % w)
	assert_almost_eq(EndlessPlan.mini_boss_power(5), 1.1489, 0.0001)
	assert_almost_eq(EndlessPlan.mini_boss_power(15), 1.5149, 0.0001)
	assert_almost_eq(EndlessPlan.mini_boss_power(35), 2.2349, 0.0001)
	assert_eq(EndlessPlan.boss_power(1), 1.0, "never less than tier 1's")


## The planned HP of a normal wave: normal_count enemies at the normal pool's
## mean (a pack: its members' mean), elite_count at the elite pool's.
func test_wave_hp_is_the_planned_total_of_a_normal_wave() -> void:
	assert_eq(EndlessPlan.wave_hp(0), 0.0)
	var normal := (240.0 + 160.0 + 240.0 + 160.0 + 620.0 / 5.0 + 675.0 / 3.0 + 870.0 / 3.0 + 500.0 + 110.0 + 130.0 + 220.0 + 150.0) / 12.0
	var elite := 12200.0 / 11.0
	assert_almost_eq(EndlessPlan.wave_hp(1), 9.0 * normal, 0.01, "9 normals, no elite, ×1")
	assert_almost_eq(EndlessPlan.wave_hp(19), (27.0 * normal + 4.0 * elite) * EndlessPlan.hp_scale(19), 0.01)
	assert_almost_eq(EndlessPlan.wave_hp(9), 12078.2, 0.1)


## P10: from the pools of the acts the waves draw from. Acts 1–3's normal
## enemies are tougher on average (256.5 a head, not 212.4).
func test_wave_hp_follows_the_acts_cleared() -> void:
	var normal := (240.0 + 160.0 + 620.0 / 5.0 + 675.0 / 3.0 + 870.0 / 3.0 + 500.0) / 6.0
	var elite := (700.0 + 1150.0 + 1400.0 + 1400.0 + 600.0) / 5.0
	assert_almost_eq(EndlessPlan.wave_hp(19, 3), (27.0 * normal + 4.0 * elite) * EndlessPlan.hp_scale(19), 0.01)
	assert_almost_eq(EndlessPlan.wave_hp(19, 0), EndlessPlan.wave_hp(19, 3), 0.01, "at least Acts 1–3")
	assert_almost_eq(EndlessPlan.boss_hp(20, 3), 26380.8, 0.1)
	assert_almost_eq(EndlessPlan.boss_hp(10, 3), 15000.0, 0.01)


## The planned HP is what the random waves bring on average.
func test_wave_hp_is_the_mean_of_the_rolled_waves() -> void:
	for acts in [3, 6]:
		for w in [9, 19, 29]:
			var total := 0.0
			var rolls := 200
			for s in rolls:
				rng.seed = s
				for id in EndlessPlan.wave(w, rng, 1, &"", &"", acts):
					total += (load(Stage.ENEMY_PATH % id) as EnemyData).max_hp
			var mean := total / rolls * EndlessPlan.hp_scale(w)
			var planned := EndlessPlan.wave_hp(w, acts)
			assert_almost_eq(mean, planned, planned * 0.06, "%d acts, wave %d" % [acts, w])


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
	assert_eq(EndlessPlan.reward_act(51), 6)


## P11: never less than the acts the save has cleared, never past Act 6.
func test_rewards_pay_at_least_like_the_acts_cleared_and_at_most_like_act_6() -> void:
	assert_eq(EndlessPlan.reward_act(1, 3), 3, "Endless opens after Act 3")
	assert_eq(EndlessPlan.reward_act(30, 3), 3)
	assert_eq(EndlessPlan.reward_act(31, 3), 4, "the wave's act once it is higher")
	assert_eq(EndlessPlan.reward_act(1, 6), 6)
	assert_eq(EndlessPlan.reward_act(61), 6, "was act 7")
	assert_eq(EndlessPlan.reward_act(200, 6), 6)


## P11: paid the first time a save wins waves 10, 20, 30 and 40.
func test_the_milestones_pay_300_blue_and_5_orange_a_tenth_wave_up_to_40() -> void:
	assert_eq(EndlessPlan.milestone(10), Vector2i(300, 5))
	assert_eq(EndlessPlan.milestone(20), Vector2i(600, 10))
	assert_eq(EndlessPlan.milestone(30), Vector2i(900, 15))
	assert_eq(EndlessPlan.milestone(40), Vector2i(1200, 20))
	for w in [0, 1, 9, 11, 15, 50, 100]:
		assert_eq(EndlessPlan.milestone(w), Vector2i.ZERO, "wave %d" % w)


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


func test_reward_scale_follows_the_tier_for_bosses_and_mini_bosses() -> void:
	assert_eq(EndlessPlan.reward_scale(&"boss", 10), 1.0)
	assert_almost_eq(EndlessPlan.reward_scale(&"boss", 20), 1.3, 0.0001)
	assert_almost_eq(EndlessPlan.reward_scale(&"boss", 30), 1.6, 0.0001)
	assert_eq(EndlessPlan.reward_scale(&"mini_boss", 5), 1.0)
	assert_almost_eq(EndlessPlan.reward_scale(&"mini_boss", 15), 1.3, 0.0001)
	assert_eq(EndlessPlan.reward_scale(&"boss", 1), 1.0, "called up early is tier 1")


func test_reward_scale_is_1_for_anything_else() -> void:
	for kind in [&"normal", &"elite"]:
		assert_eq(EndlessPlan.reward_scale(kind, 40), 1.0, str(kind))

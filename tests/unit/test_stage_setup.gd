extends GutTest
## What a stage starts with: from a save, or the Phase 4 sandbox.


func test_a_new_save_gives_almost_nothing() -> void:
	var setup := StageSetup.from_save(SaveGame.new("user://test_setup_"))
	assert_eq(setup.bought, [0, 0, 0, 0] as Array[int])
	assert_false(setup.passive)
	assert_eq(setup.equip_slots, 1)
	assert_eq(setup.shop_slots, 2)
	assert_eq(setup.refresh_cost, 100)
	assert_eq(setup.summoners, [&"", &""] as Array[StringName])
	assert_eq(setup.summoner_slots, 1)
	assert_eq(setup.skin.id, &"classic")


func test_bought_nodes_reach_the_setup() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	# Q opens with Act 1 (E's first level is not given here: only clearing Act 1 does that).
	save.tree.acts_cleared = 1
	for id in [&"skill_q", &"skill_q", &"stat_ad", &"stat_ad", &"equip_slots", &"merchant_stock", &"refresh_cost", &"flash", &"heal", &"summoner_slot_2", &"heal_upgrade"]:
		assert_true(save.tree.buy(id, save.essences), String(id))
	save.set_loadout(0, &"flash")
	save.set_loadout(1, &"heal")
	var setup := StageSetup.from_save(save)
	assert_eq(setup.bought[0], 2)
	assert_eq(setup.stat_bonus, {&"ad": 8.0})
	assert_eq(setup.equip_slots, 2)
	assert_eq(setup.shop_slots, 3)
	assert_eq(setup.refresh_cost, 75)
	assert_eq(setup.summoners, [&"flash", &"heal"] as Array[StringName])
	assert_almost_eq(setup.summoner_upgrades[&"heal"], 0.15, 0.001)


func test_f_stays_empty_without_the_second_slot() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	save.tree.buy(&"flash", save.essences)
	save.tree.buy(&"heal", save.essences)
	save.set_loadout(0, &"flash")
	save.set_loadout(1, &"heal")
	var setup := StageSetup.from_save(save)
	assert_eq(setup.summoners, [&"flash", &""] as Array[StringName])


func test_a_spell_not_bought_is_dropped_from_the_loadout() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	save.tree.buy(&"summoner_slot_2", save.essences)
	save.tree.buy(&"flash", save.essences)
	save.set_loadout(0, &"flash")
	save.set_loadout(1, &"smite")
	var setup := StageSetup.from_save(save)
	assert_eq(setup.summoners, [&"flash", &""] as Array[StringName])


func test_spell_ids_match_the_summoner_list() -> void:
	assert_eq(StageSetup.SPELL_IDS, SummonerSpells.SPELLS.map(func(s: SummonerData) -> StringName: return s.id))


func test_new_setup_is_the_phase_4_sandbox() -> void:
	var setup := StageSetup.new()
	assert_eq(setup.bought, [5, 5, 5, 3] as Array[int])
	assert_true(setup.passive)
	assert_eq(setup.equip_slots, 6)
	assert_eq(setup.shop_slots, 2)
	assert_eq(setup.summoners, [&"flash", &"heal"] as Array[StringName])
	assert_eq(setup.summoner_slots, 2)
	assert_true(setup.summoner_upgrades.is_empty())
	assert_true(setup.stat_bonus.is_empty())


func test_economy_nodes_reach_the_setup() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	save.tree.buy(&"stage_gold", save.essences)
	save.tree.buy(&"stage_gold", save.essences)
	var setup := StageSetup.from_save(save)
	assert_almost_eq(setup.gold_bonus, 0.2, 0.001)
	assert_eq(setup.xp_bonus, 0.0)
	assert_eq(setup.essence_bonus, 0.0)


func test_act_1_first_play_is_the_tutorial() -> void:
	var save := SaveGame.new("user://test_setup_")
	var setup := StageSetup.for_stage(save, 1, 1)
	assert_true(setup.tutorial)
	assert_eq(setup.bought, [0, 0, 0, 0] as Array[int])
	assert_false(setup.passive)
	assert_eq(setup.summoners, [&"", &""] as Array[StringName])
	assert_eq(setup.boss, &"thresh_1")
	assert_eq(setup.display_name, "Act 1 · The Loss")


func test_act_1_replayed_is_not_the_tutorial() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.cleared.append("1-1")
	var setup := StageSetup.for_stage(save, 1, 1)
	assert_false(setup.tutorial)
	assert_eq(setup.boss, &"")


func test_act_2_stage_3_has_akshan() -> void:
	var setup := StageSetup.for_stage(SaveGame.new("user://test_setup_"), 2, 3)
	assert_eq(setup.boss, &"akshan")
	assert_eq(setup.display_name, "Stage 2-3 · The Sentinels")


func test_each_act_starts_lucian_at_its_level() -> void:
	var save := SaveGame.new("user://test_setup_")
	var levels: Array[int] = []
	for act in range(1, Journey.ACTS.size() + 1):
		levels.append(StageSetup.for_stage(save, act, 1).start_level)
	assert_eq(levels, [1, 2, 5, 5, 7, 9] as Array[int])
	assert_eq(StageSetup.for_stage(save, 3, 4).start_level, 5, "every stage of an act")


func test_training_and_endless_start_at_level_1() -> void:
	var save := SaveGame.new("user://test_setup_")
	assert_eq(StageSetup.new().start_level, 1)
	assert_eq(StageSetup.from_save(save).start_level, 1)
	var rng := RandomNumberGenerator.new()
	assert_eq(StageSetup.for_endless(save, 5, rng).start_level, 1)


func test_a_new_setup_is_not_endless() -> void:
	var setup := StageSetup.new()
	assert_eq(setup.act, 0)
	assert_false(setup.endless)
	assert_eq(setup.map_choice, 0)
	assert_eq([setup.gold_mult, setup.blue_mult, setup.orange_mult, setup.purple_mult], [1.0, 1.0, 1.0, 1.0])


func test_endless_on_a_chosen_map() -> void:
	var rng := RandomNumberGenerator.new()
	var save := SaveGame.new("user://test_setup_")
	var setup := StageSetup.for_endless(save, 3, rng)
	assert_true(setup.endless)
	assert_eq(setup.map_choice, 3)
	assert_eq(setup.act, 3)
	assert_eq(setup.stage, 4, "the Jungle with water and Honeyfruit")
	assert_eq(setup.stage_id, "endless")
	assert_eq(setup.display_name, "Endless · Jungle")
	assert_eq(setup.boss, &"")
	assert_false(setup.tutorial)
	assert_eq(setup.bought, StageSetup.from_save(save).bought, "built on the save's setup")


## P11: an Endless run pays at least like the acts the save has cleared.
func test_endless_keeps_the_acts_the_save_has_cleared() -> void:
	var rng := RandomNumberGenerator.new()
	var save := SaveGame.new("user://test_setup_")
	assert_eq(StageSetup.new().acts_cleared, 0)
	assert_eq(StageSetup.for_endless(save, 3, rng).acts_cleared, 0)
	save.set_cleared(Journey.all_stage_ids(4))
	assert_eq(StageSetup.for_endless(save, 3, rng).acts_cleared, 4)


func test_endless_on_each_map() -> void:
	var rng := RandomNumberGenerator.new()
	var save := SaveGame.new("user://test_setup_")
	for choice in range(1, 7):
		var setup := StageSetup.for_endless(save, choice, rng)
		assert_eq(Vector2i(setup.act, setup.stage), EndlessPlan.map_for(choice))
		assert_eq(setup.display_name, "Endless · %s" % Journey.ENDLESS_MAPS[choice])


func test_endless_random_rolls_a_real_map_and_keeps_the_choice() -> void:
	var rng := RandomNumberGenerator.new()
	var save := SaveGame.new("user://test_setup_")
	var seen := {}
	for s in 100:
		rng.seed = s
		var setup := StageSetup.for_endless(save, EndlessPlan.RANDOM, rng)
		assert_eq(setup.map_choice, EndlessPlan.RANDOM, "Retry rolls again")
		assert_between(setup.act, 1, 6)
		assert_eq(Vector2i(setup.act, setup.stage), EndlessPlan.map_for(setup.act))
		assert_eq(setup.display_name, "Endless · %s" % Journey.ENDLESS_MAPS[setup.act])
		seen[setup.act] = true
	assert_eq(seen.size(), 6)


func test_regen_nodes_reach_the_stat_bonus() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	for id in [&"stat_hp_regen", &"stat_hp_regen", &"stat_mana_regen"]:
		assert_true(save.tree.buy(id, save.essences), String(id))
	var setup := StageSetup.from_save(save)
	assert_almost_eq(setup.stat_bonus[&"hp_regen"], 1.0, 0.001)
	assert_almost_eq(setup.stat_bonus[&"mana_regen"], 0.6, 0.001)


func test_a_new_save_gets_5_backpack_cells() -> void:
	var setup := StageSetup.from_save(SaveGame.new("user://test_setup_"))
	assert_eq(setup.backpack_slots, 5)


func test_backpack_levels_reach_the_setup() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.essences.from_dict({"blue": 99999, "orange": 999, "purple": 0})
	for i in 2:
		assert_true(save.tree.buy(&"backpack_slots", save.essences))
	assert_eq(StageSetup.from_save(save).backpack_slots, 16)


func test_the_sandbox_has_the_whole_backpack() -> void:
	assert_eq(StageSetup.new().backpack_slots, Inventory.BACKPACK_SIZE)


## R1: a story stage not yet cleared starts with a Resolve stack for each
## defeat there, up to 5.
func test_a_stage_carries_its_defeats_and_their_resolve_stacks() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.set_cleared(["1-1"] as Array[String])
	var fresh := StageSetup.for_stage(save, 2, 1)
	assert_eq([fresh.defeats, fresh.resolve], [0, 0], "no defeat yet")
	for i in 3:
		save.record_defeat("2-1")
	var setup := StageSetup.for_stage(save, 2, 1)
	assert_eq([setup.defeats, setup.resolve], [3, 3])
	assert_eq(StageSetup.for_stage(save, 2, 2).resolve, 0, "another stage has its own")
	for i in 4:
		save.record_defeat("2-1")
	setup = StageSetup.for_stage(save, 2, 1)
	assert_eq([setup.defeats, setup.resolve], [7, 5], "at most 5 stacks")


func test_resolve_stacks_on_hard_and_not_on_extreme() -> void:
	var save := SaveGame.new("user://test_setup_")
	for i in 2:
		save.record_defeat("1-1")
	for level in [Difficulty.EASY, Difficulty.NORMAL, Difficulty.HARD]:
		save.difficulty = level
		assert_eq(StageSetup.for_stage(save, 1, 1).resolve, 2, Difficulty.name_of(level))
	save.difficulty = Difficulty.EXTREME
	var extreme := StageSetup.for_stage(save, 1, 1)
	assert_eq([extreme.defeats, extreme.resolve], [2, 0], "Extreme has no Resolve")


func test_the_tutorial_counts_like_any_stage() -> void:
	var save := SaveGame.new("user://test_setup_")
	save.record_defeat("1-1")
	var setup := StageSetup.for_stage(save, 1, 1)
	assert_true(setup.tutorial)
	assert_eq(setup.resolve, 1)


func test_a_cleared_stage_training_endless_and_the_sandbox_have_no_resolve() -> void:
	var save := SaveGame.new("user://test_setup_")
	for i in 3:
		save.record_defeat("1-1")
		save.record_defeat("2-1")
	save.finish_stage(&"cleared", "1-1")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save.path(1)))
	var replay := StageSetup.for_stage(save, 1, 1)
	assert_eq([replay.defeats, replay.resolve], [0, 0], "a replay of a cleared stage")
	var training := StageSetup.from_save(save)
	assert_eq([training.defeats, training.resolve], [0, 0], "Training")
	var endless := StageSetup.for_endless(save, 2, RandomNumberGenerator.new())
	assert_eq([endless.defeats, endless.resolve], [0, 0], "Endless")
	var sandbox := StageSetup.new()
	assert_eq([sandbox.defeats, sandbox.resolve], [0, 0], "the sandbox")
	assert_eq(StageSetup.for_stage(save, 2, 1).resolve, 3, "the stage not cleared keeps its own")

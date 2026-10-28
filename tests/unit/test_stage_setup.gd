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

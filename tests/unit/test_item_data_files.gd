extends GutTest
## Checks data/items against the item rules in docs/lucian_game_design.md §6.

const CATALOG := "res://data/items/catalog.tres"
const FRAGMENT_CODES := ["AD", "AS", "AP", "AR", "CR", "HP", "MP", "MR"]
## The recipe table from the design doc.
const RECIPES := {
	"AD+AD": "Infinity Edge", "AD+AP": "Hextech Gunblade", "AD+AS": "Kraken Slayer",
	"AD+AR": "Mortal Reminder", "AD+CR": "Stormrazor", "AD+HP": "Black Cleaver",
	"AD+MP": "Spear of Shojin", "AD+MR": "Bloodthirster", "AS+AP": "Statikk Shiv",
	"AS+AR": "Lord Dominik's Regards", "AS+AS": "Runaan's Hurricane", "AS+CR": "Navori Flickerblade",
	"AS+HP": "Nashor's Tooth", "AS+MP": "Void Staff", "AP+AP": "Rabadon's Deathcap",
	"AP+AR": "Malignance", "AP+CR": "Shadowflame", "AP+HP": "Morellonomicon",
	"AP+MP": "Archangel's Staff", "AP+MR": "Banshee's Veil", "AR+AR": "Thornmail",
	"AR+CR": "Immortal Shieldbow", "AR+HP": "Death's Dance", "AR+MP": "Fimbulwinter",
	"AR+MR": "Guardian Angel", "CR+CR": "Rapid Firecannon", "CR+HP": "Galeforce",
	"CR+MP": "Essence Reaver", "HP+MP": "Hextech Rocketbelt", "HP+MR": "Spirit Visage",
	"MP+MP": "Muramana", "MP+MR": "Jak'Sho, The Protean", "MR+MR": "Kaenic Rookern",
}
## Each boots line: fragment -> [tier 2, tier 3] (docs/items.md, Boots).
const BOOT_LINES := {
	&"recurve_bow": [&"berserkers_greaves", &"gunmetal_greaves"],
	&"cloak_of_agility": [&"boots_of_swiftness", &"swiftmarch"],
	&"bf_sword": [&"gluttonous_greaves", &"immortal_path"],
	&"tear_of_the_goddess": [&"ionian_boots_of_lucidity", &"crimson_lucidity"],
	&"negatron_cloak": [&"mercurys_treads", &"chainlaced_crushers"],
	&"chain_vest": [&"plated_steelcaps", &"armored_advance"],
	&"needlessly_large_rod": [&"sorcerers_shoes", &"spellslingers_shoes"],
}
## The merchant's fee per upgraded pair (LoL's combine costs).
const BOOT_FEES := {
	&"berserkers_greaves": 300, &"boots_of_swiftness": 700, &"gluttonous_greaves": 800,
	&"ionian_boots_of_lucidity": 350, &"mercurys_treads": 550, &"plated_steelcaps": 600,
	&"sorcerers_shoes": 800, &"gunmetal_greaves": 500, &"swiftmarch": 500, &"immortal_path": 500,
	&"crimson_lucidity": 500, &"chainlaced_crushers": 500, &"armored_advance": 500,
	&"spellslingers_shoes": 500,
}

var catalog: ItemCatalog


func before_all() -> void:
	catalog = load(CATALOG) as ItemCatalog


func test_catalog_has_8_fragments_and_33_legendaries() -> void:
	assert_not_null(catalog)
	assert_eq(catalog.fragments().size(), 8)
	assert_eq(catalog.legendaries().size(), 33)


func test_catalog_has_the_two_potions() -> void:
	var ids := catalog.potions().map(func(item: ItemData) -> StringName: return item.id)
	assert_eq(ids, [&"hp_potion", &"mp_potion"])


func test_potions_stack_to_9_and_restore_over_time() -> void:
	for potion in catalog.potions():
		assert_eq(potion.max_stack, 9, str(potion.id))
		assert_gt(potion.restore_hp + potion.restore_mana, 0.0, str(potion.id))
		assert_gt(potion.restore_time, 0.0, str(potion.id))
		assert_eq(potion.stats.size(), 0, "%s should give no stats" % potion.id)


func test_only_potions_stack() -> void:
	for item in catalog.items:
		if not item.is_potion():
			assert_eq(item.max_stack, 1, str(item.id))


func test_sell_ratios() -> void:
	for item in catalog.items:
		var expected := 0.4 if item.id == &"guardian_angel" else 0.7
		assert_almost_eq(item.sell_ratio, expected, 0.0001, str(item.id))


func test_ids_are_unique() -> void:
	var seen := {}
	for item in catalog.items:
		assert_false(seen.has(item.id), "duplicate id %s" % item.id)
		seen[item.id] = true


func test_fragment_costs_and_stats() -> void:
	var expect := {
		&"bf_sword": [1100, &"ad", 30.0],
		&"needlessly_large_rod": [1050, &"ap", 52.0],
		&"recurve_bow": [950, &"attack_speed", 0.24],
		&"giants_belt": [900, &"max_hp", 350.0],
		&"negatron_cloak": [900, &"mr", 40.0],
		&"chain_vest": [850, &"armor", 42.0],
		&"cloak_of_agility": [750, &"crit_chance", 0.19],
		&"tear_of_the_goddess": [650, &"max_mana", 490.0],
	}
	assert_eq(catalog.fragments().size(), expect.size())
	for id: StringName in expect:
		var fragment := catalog.find(id)
		assert_eq(fragment.cost, expect[id][0], "%s cost" % id)
		assert_eq(fragment.stats.keys(), [expect[id][1]], "%s gives one stat" % id)
		assert_almost_eq(fragment.stats.get(expect[id][1], 0.0), expect[id][2], 0.0001, "%s stat" % id)


func test_craft_fees_run_from_900_to_1600() -> void:
	var fees: Array[int] = []
	for legendary in catalog.legendaries():
		fees.append(catalog.craft_fee(catalog.find(legendary.components[0]), catalog.find(legendary.components[1])))
	assert_eq(fees.min(), 900)
	assert_eq(fees.max(), 1600)


func test_fragments_use_the_eight_codes() -> void:
	var codes := catalog.fragments().map(func(item: ItemData) -> String: return item.code)
	codes.sort()
	var expected := FRAGMENT_CODES.duplicate()
	expected.sort()
	assert_eq(codes, expected)


func test_recipes_match_the_design_doc() -> void:
	var found := {}
	for legendary in catalog.legendaries():
		assert_eq(legendary.components.size(), 2, legendary.display_name)
		var codes := [catalog.find(legendary.components[0]).code, catalog.find(legendary.components[1]).code]
		codes.sort_custom(func(a: String, b: String) -> bool:
			return FRAGMENT_CODES.find(a) < FRAGMENT_CODES.find(b))
		var key := "+".join(codes)
		assert_false(found.has(key), "two legendaries use %s" % key)
		found[key] = legendary.display_name
	assert_eq(found, RECIPES)


func test_free_pairs_stay_free() -> void:
	for pair in [["AS", "MR"], ["CR", "MR"], ["HP", "HP"]]:
		var a := _fragment(pair[0])
		var b := _fragment(pair[1])
		assert_null(catalog.combine(a, b), "%s + %s" % pair)


func test_the_penetration_items_are_lord_dominiks_mortal_reminder_and_void_staff() -> void:
	var ids := catalog.items.filter(func(item: ItemData) -> bool: return item.is_penetration()).map(
		func(item: ItemData) -> String: return String(item.id))
	ids.sort()
	assert_eq(ids, ["lord_dominiks_regards", "mortal_reminder", "void_staff"])
	assert_eq(catalog.find(&"shadowflame").stats.get(&"magic_pen_flat", 0.0), 15.0, "15 flat, like Sorcerer's Shoes")
	assert_false(catalog.find(&"shadowflame").stats.has(&"magic_pen"))


func test_every_item_has_a_name_cost_and_known_stats() -> void:
	for item in catalog.items:
		assert_ne(item.display_name, "", str(item.id))
		assert_ne(item.code, "", str(item.id))
		if item.is_boots():
			assert_eq(item.cost, 0, "%s: boots are never bought or sold" % item.id)
		else:
			assert_gt(item.cost, 0, str(item.id))
		if not item.is_potion():
			assert_gt(item.stats.size(), 0, "%s gives no stats" % item.id)
		for key in item.stats:
			assert_true(ItemStats.is_known(key), "%s has unknown stat %s" % [item.id, key])
			assert_gt(item.stats[key], 0.0, "%s %s" % [item.id, key])


func test_every_item_has_its_icon() -> void:
	for item in catalog.items:
		assert_not_null(item.icon, "%s has no icon" % item.id)
		if item.icon:
			assert_eq(item.icon.resource_path, "res://assets/art/items/%s.svg" % item.id)


func test_effects_have_names_and_text() -> void:
	for item in catalog.legendaries() + catalog.boots():
		for effect in item.effects:
			assert_ne(effect.effect_name, "", str(item.id))
			assert_ne(effect.description, "", str(item.id))
			assert_true(not effect.active or effect.cooldown > 0.0, "%s active needs a cooldown" % item.id)


func test_catalog_has_16_boots() -> void:
	assert_eq(catalog.boots().size(), 16)
	for boots in catalog.boots():
		assert_eq(boots.max_stack, 1, str(boots.id))
		assert_eq(boots.sell_price(), 0, "%s can't be sold" % boots.id)
		assert_true(boots.stats.has(&"move_speed"), "%s gives move speed" % boots.id)


func test_the_two_tier_1_boots() -> void:
	for id in [&"boots_of_speed", &"slightly_magical_boots"]:
		var boots := catalog.find(id)
		assert_eq(boots.boots_tier, 1, str(id))
		assert_eq(boots.stats, {&"move_speed": 25.0} as Dictionary[StringName, float], str(id))
		assert_eq(boots.upgrade_cost, 0, str(id))
	assert_eq(catalog.find(&"boots_of_speed").effects.size(), 0)
	var magical := catalog.find(&"slightly_magical_boots")
	assert_eq(magical.effects.size(), 1)
	assert_eq(magical.effects[0].effect_name, "Slightly Quicker")


func test_each_line_links_its_fragment_tier_2_and_tier_3() -> void:
	for fragment_id: StringName in BOOT_LINES:
		assert_not_null(catalog.find(fragment_id), str(fragment_id))
		var tier_2 := catalog.find(BOOT_LINES[fragment_id][0])
		var tier_3 := catalog.find(BOOT_LINES[fragment_id][1])
		assert_eq(tier_2.boots_tier, 2, str(tier_2.id))
		assert_eq(tier_2.upgrade_fragment, fragment_id, str(tier_2.id))
		assert_eq(tier_2.upgrade_from, &"", "%s comes from either tier-1 pair" % tier_2.id)
		assert_eq(tier_3.boots_tier, 3, str(tier_3.id))
		assert_eq(tier_3.upgrade_fragment, fragment_id, str(tier_3.id))
		assert_eq(tier_3.upgrade_from, tier_2.id, str(tier_3.id))
	for id: StringName in BOOT_FEES:
		assert_eq(catalog.find(id).upgrade_cost, BOOT_FEES[id], "%s fee" % id)


func test_giants_belt_has_no_boots_line() -> void:
	for boots in catalog.boots():
		assert_ne(boots.upgrade_fragment, &"giants_belt", str(boots.id))


func test_boot_stats_follow_lol() -> void:
	var expect := {
		&"berserkers_greaves": {&"attack_speed": 0.3, &"move_speed": 45.0},
		&"gunmetal_greaves": {&"attack_speed": 0.45, &"lifesteal": 0.05, &"move_speed": 45.0},
		&"boots_of_swiftness": {&"move_speed": 55.0, &"slow_resist": 0.25},
		&"swiftmarch": {&"move_speed": 65.0, &"slow_resist": 0.25},
		&"gluttonous_greaves": {&"move_speed": 45.0, &"omnivamp": 0.04},
		&"immortal_path": {&"move_speed": 45.0, &"omnivamp": 0.04},
		&"ionian_boots_of_lucidity": {&"ability_haste": 10.0, &"move_speed": 45.0, &"summoner_haste": 10.0},
		&"crimson_lucidity": {&"ability_haste": 20.0, &"move_speed": 45.0, &"summoner_haste": 20.0},
		&"mercurys_treads": {&"mr": 20.0, &"move_speed": 45.0, &"tenacity": 0.3},
		&"chainlaced_crushers": {&"mr": 25.0, &"move_speed": 45.0, &"tenacity": 0.3},
		&"plated_steelcaps": {&"armor": 25.0, &"move_speed": 45.0},
		&"armored_advance": {&"armor": 35.0, &"move_speed": 45.0},
		&"sorcerers_shoes": {&"magic_pen_flat": 12.0, &"move_speed": 45.0},
		&"spellslingers_shoes": {&"magic_pen": 0.08, &"magic_pen_flat": 20.0, &"move_speed": 45.0},
	}
	for id: StringName in expect:
		var stats: Dictionary = expect[id]
		var boots := catalog.find(id)
		assert_eq(boots.stats.size(), stats.size(), str(id))
		for key: StringName in stats:
			assert_almost_eq(boots.stats.get(key, 0.0), stats[key], 0.0001, "%s %s" % [id, key])


func test_boot_passives_by_name() -> void:
	var expect := {
		&"gluttonous_greaves": ["Slay"], &"immortal_path": ["Slay", "Now and Forever"],
		&"swiftmarch": ["Noxian Fervor"], &"crimson_lucidity": ["Noxian Haste"],
		&"chainlaced_crushers": ["Noxian Persistence"], &"plated_steelcaps": ["Plating"],
		&"armored_advance": ["Plating", "Noxian Endurance"],
	}
	for boots in catalog.boots():
		var names: Array = boots.effects.map(func(effect: ItemEffect) -> String: return effect.effect_name)
		if boots.id == &"slightly_magical_boots":
			continue
		assert_eq(names, expect.get(boots.id, []), str(boots.id))


func _fragment(code: String) -> ItemData:
	for item in catalog.fragments():
		if item.code == code:
			return item
	return null

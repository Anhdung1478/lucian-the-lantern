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

var catalog: ItemCatalog


func before_all() -> void:
	catalog = load(CATALOG) as ItemCatalog


func test_catalog_has_8_fragments_and_33_legendaries() -> void:
	assert_not_null(catalog)
	assert_eq(catalog.fragments().size(), 8)
	assert_eq(catalog.legendaries().size(), 33)


func test_ids_are_unique() -> void:
	var seen := {}
	for item in catalog.items:
		assert_false(seen.has(item.id), "duplicate id %s" % item.id)
		seen[item.id] = true


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


func test_every_item_has_a_name_cost_and_known_stats() -> void:
	for item in catalog.items:
		assert_ne(item.display_name, "", str(item.id))
		assert_ne(item.code, "", str(item.id))
		assert_gt(item.cost, 0, str(item.id))
		assert_gt(item.stats.size(), 0, "%s gives no stats" % item.id)
		for key in item.stats:
			assert_true(ItemStats.is_known(key), "%s has unknown stat %s" % [item.id, key])
			assert_gt(item.stats[key], 0.0, "%s %s" % [item.id, key])


func test_effects_have_names_and_text() -> void:
	for item in catalog.legendaries():
		for effect in item.effects:
			assert_ne(effect.effect_name, "", str(item.id))
			assert_ne(effect.description, "", str(item.id))
			assert_true(not effect.active or effect.cooldown > 0.0, "%s active needs a cooldown" % item.id)


func _fragment(code: String) -> ItemData:
	for item in catalog.fragments():
		if item.code == code:
			return item
	return null

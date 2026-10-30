extends GutTest
## Checks data/tree against the node table in the Phase 5 plan.

const STAT_B := [50, 100, 200, 350, 500]
const STAT_O := [0, 0, 0, 3, 8]
const SKILL_B := [100, 200, 350, 500, 800]
const SKILL_O := [0, 0, 0, 5, 10]
const UP_B := [150, 300, 400]
const UP_O := [0, 0, 5]
const ECO_B := [100, 250, 500]
const ECO_O := [0, 0, 5]
const SPELLS := [&"flash", &"ghost", &"barrier", &"heal", &"clarity", &"smite"]
## id -> [blue, orange] per level.
const COSTS := {
	&"skill_q": [SKILL_B, SKILL_O], &"skill_w": [SKILL_B, SKILL_O],
	&"skill_e": [[0, 200, 350, 500, 800], SKILL_O],
	&"passive": [[150], [0]], &"skill_r": [[600, 1200, 2000], [10, 20, 30]],
	&"stat_ad": [STAT_B, STAT_O], &"stat_ap": [STAT_B, STAT_O], &"stat_hp": [STAT_B, STAT_O],
	&"stat_armor": [STAT_B, STAT_O], &"stat_mr": [STAT_B, STAT_O],
	&"stat_attack_speed": [STAT_B, STAT_O], &"stat_mana": [STAT_B, STAT_O],
	&"stat_hp_regen": [STAT_B, STAT_O], &"stat_mana_regen": [STAT_B, STAT_O],
	&"equip_slots": [[150, 300, 600, 1000, 1500], [0, 0, 5, 15, 30]],
	&"backpack_slots": [[50, 100, 200, 350, 500, 800, 1200], [0, 0, 0, 3, 8, 15, 25]],
	&"stage_gold": [ECO_B, ECO_O], &"bonus_xp": [ECO_B, ECO_O], &"essence_drop": [ECO_B, ECO_O],
	&"merchant_stock": [[300, 800], [0, 10]], &"refresh_cost": [[200, 500], [0, 5]],
	&"flash": [[150], [0]], &"ghost": [[0], [0]], &"barrier": [[150], [0]],
	&"heal": [[150], [0]], &"clarity": [[150], [0]], &"smite": [[150], [0]],
	&"flash_upgrade": [UP_B, UP_O], &"ghost_upgrade": [UP_B, UP_O], &"barrier_upgrade": [UP_B, UP_O],
	&"heal_upgrade": [UP_B, UP_O], &"clarity_upgrade": [UP_B, UP_O], &"smite_upgrade": [UP_B, UP_O],
	&"summoner_slot_2": [[400], [5]],
}

var nodes: Array[TreeNodeData]


func before_all() -> void:
	nodes = EvolutionTree.new().nodes()


func test_34_nodes_with_unique_ids() -> void:
	assert_eq(nodes.size(), 34)
	var seen := {}
	for data in nodes:
		assert_false(seen.has(data.id), "duplicate %s" % data.id)
		seen[data.id] = true


func test_every_node_has_name_description_and_icon() -> void:
	for data in nodes:
		assert_ne(data.display_name, "", str(data.id))
		assert_ne(data.description, "", str(data.id))
		assert_not_null(data.icon, str(data.id))
		assert_eq(data.icon.resource_path, _expected_icon_path(data.id), str(data.id))


## The stage's own icon for skill and summoner nodes, else tree/<id>.svg.
func _expected_icon_path(id: StringName) -> String:
	var skill_ids: Array[StringName] = [&"skill_q", &"skill_w", &"skill_e", &"skill_r"]
	if id == &"passive":
		return Hud.PASSIVE_ICON.resource_path
	if id in skill_ids:
		return Hud.SKILL_ICONS[skill_ids.find(id)].resource_path
	if id in SPELLS:
		var summoner: SummonerData = load("res://data/summoners/%s.tres" % id)
		return summoner.icon.resource_path
	return "res://assets/art/tree/%s.svg" % id


func test_cost_arrays_match_max_level() -> void:
	for data in nodes:
		assert_eq(data.blue.size(), data.max_level, str(data.id))
		assert_eq(data.orange.size(), data.max_level, str(data.id))


func test_requirements_exist() -> void:
	var ids: Array[StringName] = []
	for data in nodes:
		ids.append(data.id)
	for data in nodes:
		for required in data.requires:
			assert_true(required in ids, "%s requires %s" % [data.id, required])
		assert_true(data.requires_count <= data.requires.size(), str(data.id))


func test_costs_match_the_table() -> void:
	assert_eq(COSTS.size(), 34)
	for data in nodes:
		assert_true(COSTS.has(data.id), str(data.id))
		var expected: Array = COSTS[data.id]
		assert_eq(Array(data.blue), expected[0], "%s blue" % data.id)
		assert_eq(Array(data.orange), expected[1], "%s orange" % data.id)


func test_upgrades_are_named_after_their_spell() -> void:
	var tree := EvolutionTree.new()
	for spell in SPELLS:
		var upgrade := tree.node(StringName("%s_upgrade" % spell))
		assert_not_null(upgrade, str(spell))
		assert_eq(Array(upgrade.requires), [spell])


func test_regen_nodes_give_half_and_six_tenths_a_second_per_level() -> void:
	var hp := EvolutionTree.new().node(&"stat_hp_regen")
	var mana := EvolutionTree.new().node(&"stat_mana_regen")
	assert_eq(hp.branch, &"stats")
	assert_eq(mana.branch, &"stats")
	assert_eq(hp.value_text(0), "None")
	assert_eq(hp.value_text(1), "+0.5/s Health Regen")
	assert_eq(hp.value_text(5), "+2.5/s Health Regen")
	assert_eq(mana.value_text(1), "+0.6/s Mana Regen")
	assert_eq(mana.value_text(5), "+3/s Mana Regen")


## Each branch has a page of its own, so a cell is unique within its branch.
func test_grid_cells_are_unique_within_a_branch() -> void:
	var seen := {}
	for data in nodes:
		var cell := _cell(data.branch, data.grid)
		assert_false(seen.has(cell), "%s shares a cell" % data.id)
		seen[cell] = true


## The per-level arrays line up with max_level, so the pages and the info column can index them.
func test_level_sums_acts_and_values_match_max_level() -> void:
	for data in nodes:
		assert_eq(data.level_sum_ids.is_empty(), data.level_sums.is_empty(), "%s: sums only with ids" % data.id)
		if not data.level_sum_ids.is_empty():
			assert_eq(data.level_sums.size(), data.max_level, "%s level_sums" % data.id)
		assert_lte(data.level_acts.size(), data.max_level, "%s level_acts" % data.id)
		if not data.level_values.is_empty():
			assert_eq(data.level_values.size(), data.max_level + 1, "%s level_values" % data.id)


func _cell(branch: StringName, grid: Vector2) -> String:
	return "%s %s" % [branch, grid]


func test_backpack_slots_values_and_text() -> void:
	var data := EvolutionTree.new().node(&"backpack_slots")
	assert_eq(data.branch, &"backpack")
	assert_eq(Array(data.level_values), [5.0, 10.0, 16.0, 22.0, 29.0, 37.0, 45.0, 54.0])
	assert_eq(data.level_values.size(), data.max_level + 1)
	assert_eq(data.value_text(0), "5 backpack slots")
	assert_eq(data.value_text(1), "10 backpack slots")
	assert_eq(data.value_text(7), "54 backpack slots")
	assert_eq(roundi(data.value(data.max_level)), Inventory.BACKPACK_SIZE)

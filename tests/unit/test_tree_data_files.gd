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
	&"equip_slots": [[150, 300, 600, 1000, 1500], [0, 0, 5, 15, 30]],
	&"stage_gold": [ECO_B, ECO_O], &"bonus_xp": [ECO_B, ECO_O], &"essence_drop": [ECO_B, ECO_O],
	&"merchant_stock": [[300, 800], [0, 10]], &"refresh_cost": [[200, 500], [0, 5]],
	&"flash": [[150], [0]], &"ghost": [[150], [0]], &"barrier": [[150], [0]],
	&"heal": [[150], [0]], &"clarity": [[150], [0]], &"smite": [[150], [0]],
	&"flash_upgrade": [UP_B, UP_O], &"ghost_upgrade": [UP_B, UP_O], &"barrier_upgrade": [UP_B, UP_O],
	&"heal_upgrade": [UP_B, UP_O], &"clarity_upgrade": [UP_B, UP_O], &"smite_upgrade": [UP_B, UP_O],
	&"summoner_slot_2": [[400], [5]],
}

var nodes: Array[TreeNodeData]


func before_all() -> void:
	nodes = EvolutionTree.new().nodes()


func test_31_nodes_with_unique_ids() -> void:
	assert_eq(nodes.size(), 31)
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
	assert_eq(COSTS.size(), 31)
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

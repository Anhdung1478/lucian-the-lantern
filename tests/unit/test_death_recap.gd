extends GutTest
## R3: the defeat screen's recap: what killed Lucian, what hurt him most, a tip.

var tree: EvolutionTree
var essences: Essences


func before_each() -> void:
	tree = EvolutionTree.new()
	essences = Essences.new()


## Stats where Lucian took `taken` (source id -> damage) and the last hit
## came from `last`.
func _stats(taken: Dictionary, last: StringName, with := &"basic") -> StageStats:
	var stats := StageStats.new()
	stats.damage_by_source = taken
	stats.damage_taken = 0.0
	for amount: float in taken.values():
		stats.damage_taken += amount
	stats.last_hit_by = last
	stats.last_hit_with = with
	return stats


func _build(stats: StageStats) -> Dictionary:
	return DeathRecap.build(stats, tree, essences)


func test_the_killer_is_named_by_its_display_name() -> void:
	var recap := _build(_stats({&"ranged_minion": 10.0}, &"ranged_minion"))
	assert_eq(recap.killed, "Killed by Ranged Minion")


func test_a_burn_or_hazard_with_no_enemy_has_a_plain_name() -> void:
	assert_eq(_build(_stats({&"burn": 10.0}, &"burn", &"burn")).killed, "Killed by A burn")
	assert_eq(_build(_stats({&"mystery_pit": 10.0}, &"mystery_pit")).killed, "Killed by Mystery Pit")


func test_a_burn_an_enemy_left_names_the_enemy() -> void:
	var recap := _build(_stats({&"gromp": 10.0}, &"gromp", &"burn"))
	assert_eq(recap.killed, "Killed by Gromp's burn")


func test_the_top_three_sources_share_all_the_damage() -> void:
	var recap := _build(_stats({&"raptor": 10.0, &"gromp": 50.0, &"melee_minion": 25.0, &"burn": 15.0}, &"gromp"))
	assert_eq(recap.shares, ["Gromp 50%", "Melee Minion 25%", "A burn 15%"] as Array[String])


func test_fewer_sources_make_fewer_shares() -> void:
	assert_eq(_build(_stats({&"gromp": 7.0}, &"gromp")).shares, ["Gromp 100%"] as Array[String])
	assert_eq(_build(_stats({&"gromp": 1.0, &"raptor": 2.0}, &"gromp")).shares, ["Raptor 67%", "Gromp 33%"] as Array[String])


func test_no_damage_taken_gives_no_recap() -> void:
	assert_true(_build(StageStats.new()).is_empty())


func test_the_tip_follows_the_top_source() -> void:
	var expected := {
		&"ranged_minion": DeathRecap.TIP_RANGED, &"gromp": DeathRecap.TIP_RANGED,
		&"melee_minion": DeathRecap.TIP_MELEE, &"raptor": DeathRecap.TIP_MELEE, &"murkwolf": DeathRecap.TIP_MELEE,
		&"ghoul": DeathRecap.TIP_MELEE, &"sapling": DeathRecap.TIP_MELEE,
		&"siege_minion": DeathRecap.TIP_MARKS, &"shadow_siege_minion": DeathRecap.TIP_MARKS,
		&"super_minion": DeathRecap.TIP_ELITE, &"blue_sentinel": DeathRecap.TIP_ELITE, &"spectral_rider": DeathRecap.TIP_ELITE,
		&"elise": DeathRecap.TIP_BOSS, &"karthus": DeathRecap.TIP_BOSS, &"thresh_1": DeathRecap.TIP_BOSS,
		&"burn": DeathRecap.TIP_BURN,
	}
	for id: StringName in expected:
		assert_eq(_build(_stats({id: 10.0, &"melee_minion": 1.0}, id)).tip, expected[id], String(id))


func test_every_enemy_has_a_short_tip() -> void:
	for tip: String in [DeathRecap.TIP_RANGED, DeathRecap.TIP_MELEE, DeathRecap.TIP_MARKS, DeathRecap.TIP_ELITE, DeathRecap.TIP_BOSS, DeathRecap.TIP_BURN]:
		assert_lt(tip.length(), 91, tip)
	for file in DirAccess.get_files_at("res://data/enemies"):
		var id := file.get_basename()
		assert_ne(_build(_stats({StringName(id): 1.0}, StringName(id))).tip, "", id)


func test_the_tree_line_shows_only_when_something_can_be_bought() -> void:
	var stats := _stats({&"gromp": 10.0}, &"gromp")
	assert_eq(_build(stats).tree, "", "no essences: nothing to buy")
	essences.add(Essences.BLUE, 100000)
	essences.add(Essences.ORANGE, 100000)
	assert_eq(_build(stats).tree, DeathRecap.TREE_LINE)

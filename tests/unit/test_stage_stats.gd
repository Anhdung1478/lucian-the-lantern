extends GutTest


func test_the_counters_start_at_zero() -> void:
	var stats := StageStats.new()
	assert_eq(stats.kills, 0)
	assert_eq(stats.damage_dealt, 0.0)
	assert_eq(stats.damage_taken, 0.0)
	assert_eq(stats.gold_earned, 0)


func test_numbers_use_commas_under_10000() -> void:
	assert_eq(StageStats.format(0), "0")
	assert_eq(StageStats.format(87), "87")
	assert_eq(StageStats.format(1000), "1,000")
	assert_eq(StageStats.format(6140), "6,140")
	assert_eq(StageStats.format(9999), "9,999")


func test_numbers_use_k_from_10000() -> void:
	assert_eq(StageStats.format(10000), "10.0k")
	assert_eq(StageStats.format(41234), "41.2k")


func _hit(by: Node, source: StringName) -> DamageInfo:
	return DamageInfo.create(1.0, DamageInfo.Type.PHYSICAL, source, by)


func _unit(id: StringName) -> EnemyUnit:
	var unit := EnemyUnit.new()
	unit.data = load(Stage.ENEMY_PATH % id)
	add_child_autofree(unit)
	return unit


func test_hits_are_summed_per_enemy_and_per_source() -> void:
	var stats := StageStats.new()
	var gromp := _unit(&"gromp")
	var raptor := _unit(&"raptor")
	stats.record_hit(_hit(gromp, &"basic"), 10.0)
	stats.record_hit(_hit(raptor, &"basic"), 4.0)
	stats.record_hit(_hit(gromp, &"basic"), 6.0)
	stats.record_hit(_hit(null, &"burn"), 3.0)
	assert_eq(stats.damage_by_source, {&"gromp": 16.0, &"raptor": 4.0, &"burn": 3.0})
	assert_eq(stats.damage_taken, 23.0, "the total still counts")


func test_the_last_hit_names_who_and_with_what() -> void:
	var stats := StageStats.new()
	stats.record_hit(_hit(_unit(&"gromp"), &"basic"), 10.0)
	stats.record_hit(_hit(_unit(&"raptor"), &"burn"), 2.0)
	assert_eq([stats.last_hit_by, stats.last_hit_with], [&"raptor", &"burn"])
	stats.record_hit(_hit(null, &"burn"), 2.0)
	assert_eq([stats.last_hit_by, stats.last_hit_with], [&"burn", &"burn"], "no enemy: the source")

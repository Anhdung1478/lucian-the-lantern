extends GutTest

const IDS := ["melee_minion", "ranged_minion", "siege_minion", "super_minion", "thresh_1"]


func _data(id: String) -> EnemyData:
	return load("res://data/enemies/%s.tres" % id) as EnemyData


func test_every_enemy_file_is_complete() -> void:
	for id in IDS:
		var data := _data(id)
		assert_not_null(data, id)
		assert_eq(data.id, StringName(id))
		assert_not_null(data.art, "%s art" % id)
		assert_true(data.kind in [&"normal", &"elite", &"boss"], "%s kind" % id)


func test_the_ranged_minion_is_a_magic_kiter() -> void:
	var data := _data("ranged_minion")
	assert_eq(data.damage_type, DamageInfo.Type.MAGIC)
	assert_lt(data.keep_min, data.keep_max)
	assert_lte(data.keep_max, data.attack_range)


func test_the_siege_minion_marks_a_circle_for_a_second() -> void:
	var data := _data("siege_minion")
	assert_eq(data.area_radius, 110.0)
	assert_eq(data.warn_time, 1.0)


func test_the_super_minion_empowers_500_around_it() -> void:
	assert_eq(_data("super_minion").empower_radius, 500.0)

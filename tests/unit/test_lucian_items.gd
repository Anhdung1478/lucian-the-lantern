extends GutTest

var lucian: Lucian


func before_each() -> void:
	lucian = load("res://src/lucian/lucian.tscn").instantiate()
	add_child_autofree(lucian)


func test_make_damage_carries_penetration() -> void:
	lucian.stats.armor_pen = 0.3
	lucian.stats.magic_pen = 0.4
	var info := lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q")
	assert_eq(info.attacker, lucian)
	assert_almost_eq(info.armor_pen, 0.3, 0.0001)
	assert_almost_eq(info.magic_pen, 0.4, 0.0001)


func test_penetration_raises_damage_on_the_dummy() -> void:
	var dummy: TrainingDummy = load("res://src/enemies/training_dummy.tscn").instantiate()
	add_child_autofree(dummy)
	var plain := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q"))
	lucian.stats.armor_pen = 0.5
	var pierced := dummy.take_damage(lucian.make_damage(100.0, DamageInfo.Type.PHYSICAL, &"q"))
	assert_gt(pierced, plain)

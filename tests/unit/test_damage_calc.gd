extends GutTest

const Type := DamageInfo.Type


func test_zero_resist_takes_full_damage() -> void:
	assert_almost_eq(DamageCalc.resist_multiplier(0.0), 1.0, 0.0001)


func test_100_resist_halves_damage() -> void:
	assert_almost_eq(DamageCalc.resist_multiplier(100.0), 0.5, 0.0001)


func test_negative_resist_amplifies_damage() -> void:
	assert_almost_eq(DamageCalc.resist_multiplier(-50.0), 2.0 - 100.0 / 150.0, 0.0001)


func test_physical_uses_armor() -> void:
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.PHYSICAL, 100.0, 0.0), 100.0, 0.001)


func test_magic_uses_mr() -> void:
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.MAGIC, 0.0, 100.0), 100.0, 0.001)


func test_true_damage_ignores_resists() -> void:
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.TRUE, 300.0, 300.0), 200.0, 0.001)


func test_crit_roll_edges() -> void:
	assert_false(DamageCalc.is_crit(0.0, 0.0), "0% never crits")
	assert_true(DamageCalc.is_crit(1.0, 0.9999), "100% always crits")
	assert_true(DamageCalc.is_crit(0.25, 0.24))
	assert_false(DamageCalc.is_crit(0.25, 0.25))


func test_pierce_falloff_drops_15_percent_per_hit() -> void:
	assert_almost_eq(DamageCalc.falloff_multiplier(0, 0.15, 0.3), 1.0, 0.0001)
	assert_almost_eq(DamageCalc.falloff_multiplier(1, 0.15, 0.3), 0.85, 0.0001)
	assert_almost_eq(DamageCalc.falloff_multiplier(4, 0.15, 0.3), 0.4, 0.0001)


func test_pierce_falloff_floors_at_minimum() -> void:
	assert_almost_eq(DamageCalc.falloff_multiplier(5, 0.15, 0.3), 0.3, 0.0001)
	assert_almost_eq(DamageCalc.falloff_multiplier(20, 0.15, 0.3), 0.3, 0.0001)


func test_damage_info_create() -> void:
	var info := DamageInfo.create(50.0, Type.MAGIC, &"w", null, true)
	assert_eq(info.amount, 50.0)
	assert_eq(info.type, Type.MAGIC)
	assert_eq(info.source, &"w")
	assert_true(info.is_crit)


func test_armor_pen_lowers_positive_armor() -> void:
	# 100 armor with 50% pen counts as 50 armor.
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.PHYSICAL, 100.0, 0.0, 0.5, 0.0), 200.0 * 100.0 / 150.0, 0.001)


func test_magic_pen_lowers_positive_mr() -> void:
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.MAGIC, 0.0, 100.0, 0.0, 0.5), 200.0 * 100.0 / 150.0, 0.001)


func test_pen_leaves_negative_resist_alone() -> void:
	assert_almost_eq(
		DamageCalc.mitigate(200.0, Type.PHYSICAL, -50.0, 0.0, 0.5, 0.0),
		DamageCalc.mitigate(200.0, Type.PHYSICAL, -50.0, 0.0), 0.001)


func test_pen_only_matches_its_damage_type() -> void:
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.PHYSICAL, 100.0, 100.0, 0.0, 0.9), 100.0, 0.001)
	assert_almost_eq(DamageCalc.mitigate(200.0, Type.MAGIC, 100.0, 100.0, 0.9, 0.0), 100.0, 0.001)

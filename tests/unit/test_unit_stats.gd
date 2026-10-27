extends GutTest

var stats: UnitStats


func before_each() -> void:
	stats = UnitStats.new()
	stats.max_hp = 600.0
	stats.max_hp_growth = 95.0
	stats.hp_regen_per_5 = 4.0
	stats.hp_regen_per_5_growth = 0.6
	stats.max_mana = 320.0
	stats.max_mana_growth = 40.0
	stats.mana_regen_per_5 = 8.0
	stats.mana_regen_per_5_growth = 0.7
	stats.ad = 60.0
	stats.ad_growth = 3.0
	stats.attack_speed = 0.65
	stats.attack_speed_ratio = 0.65
	stats.attack_speed_growth = 0.03
	stats.armor = 28.0
	stats.armor_growth = 4.0
	stats.mr = 30.0
	stats.mr_growth = 1.3
	stats.move_speed = 335.0
	stats.attack_range = 500.0
	stats.crit_damage = 1.75


func test_growth_factor_is_0_at_level_1_and_17_at_level_18() -> void:
	assert_almost_eq(UnitStats.growth_factor(1), 0.0, 0.0001)
	assert_almost_eq(UnitStats.growth_factor(18), 17.0, 0.0001)


func test_growth_factor_is_curved() -> void:
	# LoL curve: early levels give less than a linear share.
	assert_almost_eq(UnitStats.growth_factor(2), 0.72, 0.0001)
	assert_lt(UnitStats.growth_factor(9), 8.0)


func test_level_1_uses_base_values() -> void:
	var block := stats.at_level(1)
	assert_almost_eq(block.max_hp, 600.0, 0.001)
	assert_almost_eq(block.ad, 60.0, 0.001)
	assert_almost_eq(block.attack_speed, 0.65, 0.001)
	assert_almost_eq(block.move_speed, 335.0, 0.001)
	assert_almost_eq(block.attack_range, 500.0, 0.001)
	assert_almost_eq(block.crit_damage, 1.75, 0.001)


func test_level_18_adds_17_growths() -> void:
	var block := stats.at_level(18)
	assert_almost_eq(block.max_hp, 600.0 + 17 * 95.0, 0.001)
	assert_almost_eq(block.max_mana, 320.0 + 17 * 40.0, 0.001)
	assert_almost_eq(block.ad, 60.0 + 17 * 3.0, 0.001)
	assert_almost_eq(block.armor, 28.0 + 17 * 4.0, 0.001)
	assert_almost_eq(block.mr, 30.0 + 17 * 1.3, 0.001)


func test_regen_is_converted_to_per_second() -> void:
	var block := stats.at_level(1)
	assert_almost_eq(block.hp_regen, 0.8, 0.0001)
	assert_almost_eq(block.mana_regen, 1.6, 0.0001)


func test_attack_speed_growth_scales_with_ratio() -> void:
	var block := stats.at_level(18)
	assert_almost_eq(block.attack_speed, 0.65 + 0.65 * 0.03 * 17, 0.0001)


func test_attack_speed_caps_at_2_5() -> void:
	stats.attack_speed_growth = 1.0
	assert_almost_eq(stats.at_level(18).attack_speed, 2.5, 0.0001)


func test_attack_period_is_inverse_of_attack_speed() -> void:
	var block := stats.at_level(1)
	assert_almost_eq(block.attack_period(), 1.0 / 0.65, 0.0001)

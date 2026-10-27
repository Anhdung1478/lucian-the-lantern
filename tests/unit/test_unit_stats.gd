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


func test_bonus_adds_flat_stats() -> void:
	var block := stats.at_level(1, {
		&"ad": 35.0, &"ap": 60.0, &"armor": 40.0, &"mr": 40.0,
		&"max_hp": 350.0, &"max_mana": 300.0, &"ability_haste": 20.0,
	})
	assert_almost_eq(block.ad, 95.0, 0.001)
	assert_almost_eq(block.ap, 60.0, 0.001)
	assert_almost_eq(block.armor, 68.0, 0.001)
	assert_almost_eq(block.mr, 70.0, 0.001)
	assert_almost_eq(block.max_hp, 950.0, 0.001)
	assert_almost_eq(block.max_mana, 620.0, 0.001)
	assert_almost_eq(block.ability_haste, 20.0, 0.001)


func test_bonus_attack_speed_scales_with_ratio() -> void:
	var block := stats.at_level(1, {&"attack_speed": 0.25})
	assert_almost_eq(block.attack_speed, 0.65 + 0.65 * 0.25, 0.0001)


func test_bonus_attack_speed_adds_to_level_growth() -> void:
	var block := stats.at_level(18, {&"attack_speed": 0.5})
	assert_almost_eq(block.attack_speed, 0.65 + 0.65 * (0.03 * 17 + 0.5), 0.0001)


func test_bonus_attack_speed_respects_cap() -> void:
	assert_almost_eq(stats.at_level(1, {&"attack_speed": 5.0}).attack_speed, 2.5, 0.0001)


func test_crit_chance_caps_at_100_percent() -> void:
	assert_almost_eq(stats.at_level(1, {&"crit_chance": 0.6}).crit_chance, 0.6, 0.0001)
	assert_almost_eq(stats.at_level(1, {&"crit_chance": 1.35}).crit_chance, 1.0, 0.0001)


func test_move_speed_percent_applies_after_flat() -> void:
	var block := stats.at_level(1, {&"move_speed": 20.0, &"move_speed_pct": 0.1})
	assert_almost_eq(block.move_speed, (335.0 + 20.0) * 1.1, 0.001)


func test_combat_stats_pass_through() -> void:
	var block := stats.at_level(1, {
		&"lifesteal": 0.15, &"omnivamp": 0.08, &"armor_pen": 0.3, &"magic_pen": 0.4,
		&"heal_shield_power": 0.1, &"tenacity": 0.2,
	})
	assert_almost_eq(block.lifesteal, 0.15, 0.0001)
	assert_almost_eq(block.omnivamp, 0.08, 0.0001)
	assert_almost_eq(block.armor_pen, 0.3, 0.0001)
	assert_almost_eq(block.magic_pen, 0.4, 0.0001)
	assert_almost_eq(block.heal_shield_power, 0.1, 0.0001)
	assert_almost_eq(block.tenacity, 0.2, 0.0001)


func test_no_bonus_leaves_item_stats_at_zero() -> void:
	var block := stats.at_level(1)
	assert_eq(block.ap, 0.0)
	assert_eq(block.crit_chance, 0.0)
	assert_eq(block.lifesteal, 0.0)
	assert_eq(block.armor_pen, 0.0)

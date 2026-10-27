extends GutTest

var data: SkillData


func before_each() -> void:
	data = SkillData.new()
	data.max_rank = 5
	data.mana_cost = [50.0, 55.0, 60.0, 65.0, 70.0]
	data.cooldown = [9.0, 8.0, 7.0, 6.0, 5.0]
	data.base_damage = [80.0, 110.0, 140.0, 170.0, 200.0]
	data.ad_ratio = [0.6, 0.7, 0.8, 0.9, 1.0]


func test_value_at_rank() -> void:
	assert_eq(data.value_at(data.cooldown, 1), 9.0)
	assert_eq(data.value_at(data.cooldown, 5), 5.0)


func test_value_at_rank_0_or_empty_is_zero() -> void:
	assert_eq(data.value_at(data.cooldown, 0), 0.0)
	assert_eq(data.value_at(data.ap_ratio, 3), 0.0)


func test_value_at_clamps_to_last_rank() -> void:
	assert_eq(data.value_at(data.mana_cost, 9), 70.0)


func test_single_value_applies_to_every_rank() -> void:
	data.mana_cost = [70.0]
	assert_eq(data.value_at(data.mana_cost, 4), 70.0)


func test_damage_scales_with_ad_and_ap() -> void:
	data.ap_ratio = [0.5]
	var stats := StatBlock.new()
	stats.ad = 100.0
	stats.ap = 40.0
	assert_almost_eq(data.damage_at(2, stats), 110.0 + 70.0 + 20.0, 0.001)

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

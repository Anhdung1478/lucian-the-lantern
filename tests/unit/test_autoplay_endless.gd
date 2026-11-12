extends GutTest
## The balance bot's Endless parts (tests/tools/autoplay.gd): its modifier
## preference, the rates maths and the name of a run's save file.

const BOT := "res://tests/tools/autoplay.gd"

var bot_script: GDScript


func before_each() -> void:
	bot_script = load(BOT)


func _best(offered: Array[int]) -> int:
	return offered[bot_script.Bot.best_card(offered, bot_script.Bot.MODIFIER_ORDER)]


func test_the_order_names_every_card_once() -> void:
	var order: Array = bot_script.Bot.MODIFIER_ORDER.duplicate()
	order.sort()
	assert_eq(order, range(1, EndlessModifiers.NOTHING + 1))


func test_blue_for_a_little_health_is_taken_first() -> void:
	assert_eq(_best([5, 3, EndlessModifiers.NOTHING]), 3)
	assert_eq(_best([4, 3, EndlessModifiers.NOTHING]), 3)


func test_nothing_beats_the_deadly_downsides() -> void:
	assert_eq(_best([1, 2, EndlessModifiers.NOTHING]), EndlessModifiers.NOTHING)
	assert_eq(_best([5, 2, EndlessModifiers.NOTHING]), EndlessModifiers.NOTHING)


func test_every_offer_gets_a_card_in_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var offered := EndlessModifiers.offer(rng, rng.randi_range(0, 5))
		assert_has(offered, _best(offered))


func test_the_first_card_when_none_is_ranked() -> void:
	var unranked: Array[int] = [9, 8]
	assert_eq(bot_script.Bot.best_card(unranked, bot_script.Bot.MODIFIER_ORDER), 0)


func test_rates_per_hour() -> void:
	assert_eq(bot_script.per_hour(100, 1800.0), 200.0)
	assert_eq(bot_script.per_hour(5, 3600.0), 5.0)
	assert_eq(bot_script.per_hour(100, 0.0), 0.0)


func test_a_runs_save_file_name() -> void:
	assert_eq(bot_script.save_prefix("skilled", Difficulty.NORMAL, ""), "user://autoplay_save_slot_skilled_normal_")
	assert_eq(bot_script.save_prefix("novice", Difficulty.HARD, "ec1"), "user://autoplay_save_slot_novice_hard_ec1_")
	assert_eq(SaveGame.new(bot_script.save_prefix("skilled", Difficulty.NORMAL, "ec1")).path(1), "user://autoplay_save_slot_skilled_normal_ec1_1.json")

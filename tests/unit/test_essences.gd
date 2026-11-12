extends GutTest

var essences: Essences


func before_each() -> void:
	essences = Essences.new()


func test_spend_pays_every_kind_at_once() -> void:
	essences.add(Essences.BLUE, 600)
	essences.add(Essences.ORANGE, 10)
	assert_true(essences.spend(500, 5))
	assert_eq(essences.amount(Essences.BLUE), 100)
	assert_eq(essences.amount(Essences.ORANGE), 5)


func test_nothing_is_paid_when_one_kind_is_short() -> void:
	essences.add(Essences.BLUE, 1000)
	assert_false(essences.spend(100, 1))
	assert_eq(essences.amount(Essences.BLUE), 1000)


func test_round_trip_turns_json_floats_back_into_ints() -> void:
	essences.from_dict({"blue": 12.0, "orange": 3.0, "purple": -4.0, "green": 9})
	assert_eq(essences.to_dict(), {"blue": 12, "orange": 3, "purple": 0})
	assert_typeof(essences.amount(Essences.BLUE), TYPE_INT)


func test_forge_turns_blue_into_orange_at_the_rate() -> void:
	essences.add(Essences.BLUE, Essences.FORGE_BLUE * 3 + 7)
	assert_true(essences.forge(1))
	assert_eq(essences.amount(Essences.BLUE), Essences.FORGE_BLUE * 2 + 7)
	assert_eq(essences.amount(Essences.ORANGE), 1)
	assert_true(essences.forge(2))
	assert_eq(essences.amount(Essences.BLUE), 7)
	assert_eq(essences.amount(Essences.ORANGE), 3)


func test_forge_needs_the_whole_price_and_changes_nothing_when_short() -> void:
	essences.add(Essences.BLUE, Essences.FORGE_BLUE * 2 - 1)
	assert_false(essences.forge(2))
	assert_eq(essences.amount(Essences.BLUE), Essences.FORGE_BLUE * 2 - 1)
	assert_eq(essences.amount(Essences.ORANGE), 0)
	assert_false(essences.forge(0))
	assert_false(essences.forge(-1))


func test_forge_ten_costs_1200_blue_and_signals_once() -> void:
	essences.add(Essences.BLUE, 1200)
	watch_signals(essences)
	assert_true(essences.forge(10))
	assert_eq(essences.amount(Essences.BLUE), 0)
	assert_eq(essences.amount(Essences.ORANGE), 10)
	assert_signal_emit_count(essences, "changed", 1)

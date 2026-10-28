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
